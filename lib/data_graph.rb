require 'data_graph/graph'

# The DataGraph module extends ActiveRecord::Base with the data_graph helper.
module DataGraph
  
  # A convenience method to generate a Graph bound to the current model. 
  # Options will be used in the initialization of both Graph, and the graph
  # Node... load it up with all the options those classes can use.
  #
  #   Model.data_graph(:only => %w{a b c}).find(:all)
  #
  def data_graph(options={})
    Graph.new(Node.new(self, options), options)
  end
end

ActiveRecord::Base.extend(DataGraph)
