require 'data_graph/node'

module DataGraph
  
  # Graph is a wrapper that adds high-level functionality to nodes which, for
  # the most part, are intended to be throwaway objects.  Specifically Graph
  # provides a way to define/resolve path aliases, and to work with named
  # subsets for quick reuse and path validation.
  class Graph
    include Utils
    
    # The graph node
    attr_reader :node
    
    # A hash of named path sets resolved against aliases.
    attr_reader :paths
    
    # A hash of named subsets that mirror the named paths.
    attr_reader :subsets
    
    def initialize(node, options={})
      @node = node
      @aliases = nil
      @nest_paths = nil
      @subsets = {}
      @paths   = {}
      
      if aliases = options[:aliases]
        @aliases = node.aliases.merge(aliases)
      end
      
      if subsets = options[:subsets]
        subsets.each_pair do |type, paths|
          register(type, paths)
        end
      end
    end
    
    # Returns a hash of aliases defined for the node (ie node.aliases).
    #
    # Non-default aliases may be defined during initialization, but afterwards
    # aliases should not be modified so as to ensure consistency of resolved
    # paths and subsets.
    def aliases
      @aliases ||= node.aliases
    end
    
    # Returns an array of nestable paths.
    def nest_paths
      @nest_paths ||= node.nest_paths
    end
    
    # Delegates to Node#find.
    def find(*args)
      node.find(*args)
    end
    
    # Delegates to Node#paginate.
    def paginate(*args)
      node.paginate(*args)
    end
    
    # Resolves paths and generates a subset graph using Node#only.
    def only(paths)
      Graph.new node.only(resolve(paths))
    end
    
    # Resolves paths and generates a subset graph using Node#except.
    def except(paths)
      Graph.new node.except(resolve(paths))
    end
    
    # Resolves paths using aliases. Returns an array of unique paths.
    def resolve(paths)
      paths = paths.collect {|path| aliases[path] || path }
      paths.flatten!
      paths.uniq!
      paths
    end
    
    # Register a new named path/subset.
    def register(type, paths)
      resolved_paths = resolve(paths)
      self.paths[type] = resolved_paths
      self.subsets[type] = only(resolved_paths)
    end
    
    # Returns the named paths.  Raises an error if no such subset exists.
    def path(type)
      paths[type] or raise "no such path: #{type.inspect}"
    end
    
    # Returns the named subset, or the default subset if the named subset does
    # not exist.  Raises an error if neither subset exists.
    def subset(type, default_type = :default)
      (subsets[type] || subsets[default_type]) or raise "no such subset: #{type.inspect}"
    end
    
    # Validates that the paths are all accessible by the named paths.  The
    # input paths are not resolved against aliases.  Raises an
    # InaccessiblePathError if the paths are not accessible.
    def validate(type, paths)
      inaccessible_paths = paths - path(type)
      unless inaccessible_paths.empty?
        raise InaccessiblePathError.new(inaccessible_paths)
      end
      paths
    end
    
    # Validates that all paths in the attrs hash are assignable, as per the
    # named paths.  Nested attr paths are resolved against nest_paths.
    def validate_attrs(type, attrs)
      validate(type, patherize_attrs(attrs, nest_paths))
      attrs
    end
  end
  
  # Raised to indicate inaccessible paths, as determined by Graph#validate.
  class InaccessiblePathError < RuntimeError
    attr_reader :paths
    
    def initialize(paths)
      @paths = paths
      super "inaccesible: #{paths.inspect}"
    end
  end
end