require 'data_graph/cpk_linkage'

module DataGraph
  
  #-- Treated as immutable once created.
  class Node
    include Utils
    
    attr_reader :model
    attr_reader :column_names
    attr_reader :method_names
    attr_reader :linkages
    attr_reader :always_columns
    
    def initialize(model, options={})
      @model = model
      
      # Attribute methods need to be defined because later on the Linkage
      # parent_id/child_id methods call read_attribute to extract keys for
      # associating child records to parents.  As a result AR will pretend
      # like attribute methods do not need to be generated for the key fields.
      # Way down the line send(:attribute) and methods that depend on it,
      # including to_json, end up breaking as a result.
      #
      # Consider it a lesson in being too smart with method_missing.
      if !model.generated_methods?
        model.define_attribute_methods
      end
      
      self.options = options
    end
    
    def associations
      linkages.keys
    end
    
    def [](name)
      linkage = linkages[name.to_s]
      linkage ? linkage.node : nil
    end
    
    def paths
      paths = column_names + method_names
      linkages.each_pair do |name, linkage|
        linkage.node.paths.each do |path|
          paths << "#{name}.#{path}"
        end
      end
      
      paths
    end
    
    def get_paths
      paths = primary_keys(model) + column_names + method_names
      linkages.each_pair do |name, linkage|
        paths << name
        paths.concat linkage.parent_columns
        (linkage.node.get_paths + linkage.child_columns).each do |path|
          paths << "#{name}.#{path}"
        end
      end
      
      paths.uniq!
      paths
    end
    
    def set_paths
      paths = primary_keys(model) + column_names + method_names
      nested_attributes = model.nested_attributes_options
      linkages.each_pair do |name, linkage|
        next unless nested_attributes.has_key?(name.to_sym)
        
        attributes = linkage.node.set_paths
        attributes += ActiveRecord::NestedAttributes::UNASSIGNABLE_KEYS
        attributes.each do |path|
          paths << "#{name}_attributes.#{path}"
        end
      end
      
      paths.uniq!
      paths
    end
    
    def nest_paths
      paths = []
      
      linkages.each_pair do |name, linkage|
        if linkage.macro == :has_many
          paths << "#{name}_attributes"
        end
        
        linkage.node.nest_paths.each do |path|
          paths << "#{name}.#{path}"
        end
      end
      
      paths
    end
    
    def aliases
      aliases = {'*' => column_names.dup}
      
      linkages.each_pair do |name, linkage|
        linkage.node.aliases.each_pair do |als, paths|
          aliases["#{name}.#{als}"] = paths.collect {|path| "#{name}.#{path}" }
        end
      end
      
      aliases
    end
    
    def options
      associations = {}
      linkages.each_pair do |name, linkage|
        associations[name.to_sym] = linkage.node.options
      end
      
      # note a new options hash must be generated because serialization is
      # destructive to the hash (although not the values)
      
      {
        :only    => column_names,
        :methods => method_names,
        :include => associations
      }
    end
    
    def options=(options)
      unless options.kind_of?(Hash)
        raise "not a hash: #{options.inspect}"
      end
      @column_names = parse_columns(options)
      @method_names = parse_methods(options)
      @linkages     = parse_linkages(options)
      @always_columns = parse_always(options)
    end
    
    def find(*args)
      link model.find(*find_args(args))
    end
    
    def paginate(*args)
      link model.paginate(*find_args(args))
    end
    
    def find_args(args=[])
      args << {} unless args.last.kind_of?(Hash)
      scope(args.last)
      args
    end
    
    def scope(options={})
      columns = arrayify(options[:select]) + column_names + always_columns
      linkages.each_value {|linkage| columns.concat linkage.parent_columns }
      columns.uniq!
      
      options[:select] = columns.join(',')
      options
    end
    
    def link(records)
      linkages.each_value do |linkage|
        linkage.link(records)
      end
      
      records
    end
    
    def only!(paths)
      attr_paths, nest_paths = partition(paths)
      source, target = linkages, {}
      
      attr_paths.each do |name|
        if linkage = source[name]
          target[name] = linkage
        end
      end
      
      nest_paths.each_pair do |name, paths|
        if linkage = source[name]
          target[name] = linkage.inherit(:only, paths)
        end
      end
      
      @column_names &= attr_paths
      @method_names &= attr_paths
      @linkages = target
      
      self
    end
    
    def only(paths)
      dup.only!(paths)
    end
    
    def except!(paths)
      attr_paths, nest_paths = partition(paths)
      source, target = linkages, {}
      
      (attr_paths - nest_paths.keys).each do |path|
        source.delete(path)
      end
      
      nest_paths.each_pair do |name, paths|
        if linkage = source[name]
          target[name] = linkage.inherit(:except, paths)
        end
      end
      
      @column_names -= attr_paths
      @method_names -= attr_paths
      @linkages = target
      
      self
    end
    
    def except(paths)
      dup.except!(paths)
    end
    
    private
    
    def arrayify(array)
      case array
      when Array then array
      when nil   then []
      else [array]
      end.collect! {|obj| obj.to_s }
    end
    
    def parse_columns(options)
      attributes = model.column_names

      case
      when options.has_key?(:except)
        if options.has_key?(:only)
          raise "only and except are both specified: #{options.inspect}"
        end

        except = options[:except]
        attributes - arrayify(except)

      when options.has_key?(:only)
        only = options[:only]
        arrayify(only) & attributes

      else
        attributes.dup
      end
    end

    def parse_methods(options)
      arrayify(options[:methods])
    end
    
    def hashify(hash)
      case hash
      when Hash   # default
        hash.symbolize_keys
      when Array  # an array of identifiers {:include => [:a, :b]}
        hash.inject({}) {|h, k| h[k.to_sym] = {}; h}
      else        # a bare identifier {:include => :a}
        {hash.to_sym => {}}
      end
    end
    
    def parse_linkages(options)
      linkages = {}
      
      hashify(options[:include] || {}).each_pair do |name, options|
        next unless assoc = model.reflect_on_association(name)
        linkage = cpk?(assoc) ? CpkLinkage : Linkage
        linkages[name.to_s] = linkage.new(assoc, options)
      end
      
      linkages
    end
    
    def parse_always(options)
      always_columns = primary_keys(model).collect {|key| key.to_s }
      always_columns.concat arrayify(options[:always])
      always_columns.uniq!
      always_columns
    end
    
    def partition(paths)
      attrs = []
      nested_attrs = {}
      
      paths.each do |path|
        head, tail = path.split('.', 2)
        
        if tail
          (nested_attrs[head] ||= []) << tail
        else
          attrs << head
        end
      end
      
      [attrs, nested_attrs]
    end
  end
end
