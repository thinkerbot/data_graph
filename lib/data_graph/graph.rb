require 'data_graph/node'

module DataGraph
  class Graph
    include Utils
    
    attr_reader :model
    attr_reader :aliases
    attr_reader :paths
    attr_reader :subsets
    attr_reader :node
    
    def initialize(node, options={})
      aliases = options[:aliases]
      subsets = options[:subsets]
      
      @node = node
      @nest_paths = node.nest_paths
      @aliases = @node.aliases
      @aliases.merge!(aliases) if aliases
      
      @paths = {}
      @subsets = {}
      
      subsets = {
        :default => '*',
        :get => node.get_paths,
        :set => node.set_paths
      }.merge(subsets || {})
      
      subsets.each_pair do |name, unresolved_paths|
        resolved_paths  = resolve(unresolved_paths)
        @paths[name]    = resolved_paths
        @subsets[name]  = node.only(resolved_paths)
      end
    end
    
    def find(*args)
      node.find(*args)
    end
    
    def paginate(*args)
      node.paginate(*args)
    end
    
    def only(paths)
      node.only validate(:get, resolve(paths))
    end
    
    def except(paths)
      node.only validate(:get, resolve(paths))
    end
    
    def resolve(paths)
      paths = paths.collect {|path| aliases[path.to_s] || path }
      paths.flatten!
      paths.collect! {|path| path.to_s }
      paths.uniq!
      paths
    end
    
    def path(type)
      paths[type] or raise "no such path: #{type.inspect}"
    end
    
    def subset(type, default_type = :default)
      (subsets[type] || subsets[default_type]) or raise "no such subset: #{type.inspect}"
    end
    
    def validate(type, paths)
      inaccessible_paths = paths - path(type)
      unless inaccessible_paths.empty?
        raise InaccessiblePathError.new(inaccessible_paths)
      end
      paths
    end
    
    def validate_attrs(type, attrs)
      validate(type, patherize_attrs(attrs, @nest_paths))
      attrs
    end
  end
  
  class InaccessiblePathError < RuntimeError
    attr_reader :paths
    
    def initialize(paths)
      @paths = paths
      super "inaccesible: #{paths.inspect}"
    end
  end
end