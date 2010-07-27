require 'active_record'
ActiveRecord.load_all!

require 'composite_primary_keys'

module DataGraph
  module Utils
    module_function
    
    def primary_keys(model)
      model.respond_to?(:primary_keys) ? model.primary_keys : [model.primary_key]
    end
    
    def foreign_key(assoc)
      # actually returns options[:foreign_key], or the default foreign key
      foreign_key = assoc.primary_key_name

      # cpk returns a csv string
      foreign_key.to_s.split(',')
    end

    def reference_key(assoc)
      primary_key = assoc.options[:primary_key] || primary_keys(assoc.macro == :belongs_to ? assoc.klass : assoc.active_record)
      primary_key.kind_of?(Array) ? primary_key.collect {|key| key.to_s } : primary_key.to_s.split(',')
    end
    
    def cpk?(assoc)
      assoc = assoc.through_reflection if assoc.through_reflection
      assoc.primary_key_name.to_s.include?(',')
    end
    
    def patherize_attrs(attrs, nest_paths=[], paths=[], prefix='')
      attrs.each_pair do |key, value|
        case key
        when String, Symbol
          path = "#{prefix}#{key}"
          
          if nest_paths.include?(path) && value.kind_of?(Hash)
            value = value.values
          end
          
          case value
          when Hash
            patherize_attrs(value, nest_paths, paths, "#{path}.")
          when Array
            next_prefix = "#{path}."
            value.each {|hash| patherize_attrs(hash, nest_paths, paths, next_prefix) }
          else
            paths << path
          end
        else
          raise "unexpected attribute key: #{key.inspect}"
        end
      end
      
      paths
    end
  end
end
