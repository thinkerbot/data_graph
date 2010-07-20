require 'data_graph/graph'

module DataGraph
  def data_graph(options={})
    Graph.new(Node.new(self, options), options)
  end
end

ActiveRecord::Base.extend(DataGraph)
