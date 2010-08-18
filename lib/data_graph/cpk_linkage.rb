require 'data_graph/linkage'

module DataGraph
  class CpkLinkage < Linkage
    def parent_id(record)
      parent_columns.collect {|attribute| record.read_attribute(attribute) }
    end
    
    def child_id(record)
      child_columns.collect {|attribute| record.read_attribute(attribute) }
    end
    
    def conditions(id_map)
      condition = child_columns.collect {|col| "#{table_name}.#{connection.quote_column_name(col)} = ?" }.join(' AND ')
      conditions = Array.new(id_map.length, condition)
      conditions_str = "(#{conditions.join(') OR (')})"
      
      id_map.keys.flatten.unshift(conditions_str)
    end
  end
end
