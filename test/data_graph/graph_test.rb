require File.expand_path('../../test_helper', __FILE__)
require 'data_graph/graph'
require 'emp'

class GraphTest < Test::Unit::TestCase
  Node = DataGraph::Node
  Graph = DataGraph::Graph
  
  include DatabaseTest
  
  attr_reader :node, :graph
  
  def setup
    super
    @node  = Node.new(Emp)
    @graph = Graph.new node
  end
  
  #
  # initialize test
  #
  
  def test_default_initialize
    assert_equal graph.aliases, graph.node.aliases
  end
  
  def test_initialize_may_define_new_aliases
    graph = Graph.new(node, :aliases => {'name_only' => %w{first_name last_name}})
    assert_equal %w{first_name last_name}, graph.aliases['name_only']
  end
  
  def test_initialize_registers_subsets
    name_columns = %w{first_name last_name}
    
    graph = Graph.new(node, :subsets => {'name_only' => name_columns})
    assert_equal name_columns, graph.paths['name_only']
    assert_equal name_columns, graph.subsets['name_only'].node.paths
  end
  
  #
  # resolve test
  #
  
  def test_resolve_resolves_aliases
    graph = Graph.new(node, :aliases => {'b' => %w{one two three}})
    assert_equal %w{a one two three c}, graph.resolve(%w{a b c})
  end
  
  def test_resolve_does_not_recurse
    graph = Graph.new(node, :aliases => {'b' => %w{one b three}})
    assert_equal %w{a one b three c}, graph.resolve(%w{a b c})
  end
  
  def test_resolve_returns_unique_paths
    graph = Graph.new(node, :aliases => {'b' => %w{x y z}})
    assert_equal %w{x y z}, graph.resolve(%w{x b z})
  end
  
  #
  # register test
  #
  
  def test_register_registers_paths_and_creates_a_subset
    assert_equal nil, graph.paths[:type]
    assert_equal nil, graph.subsets[:type]
    
    graph.register(:type, %w{first_name last_name})
    
    assert_equal %w{first_name last_name}, graph.paths[:type]
    assert_equal %w{first_name last_name}, graph.subsets[:type].node.paths
  end
  
  def test_register_returns_subset_graph
    assert_equal Graph, graph.register(:type, %w{first_name last_name}).class
  end
  
  #
  # only test
  #
  
  def test_only_returns_subset_graph_using_only
    subset = graph.only %w{
      first_name
      last_name
    }
    
    assert_equal Graph, subset.class
    assert_equal %w{
      first_name
      last_name
    }, subset.node.paths
  end
  
  #
  # except test
  #
  
  def test_except_returns_subset_graph_using_except
    subset = graph.except %w{
      first_name
      last_name
    }
    
    assert_equal Graph, subset.class
    assert_equal %w{
      id
      job_id 
      dept_id
      manager_id
      salary
    }, subset.node.paths
  end
end