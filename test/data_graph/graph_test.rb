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
    @node  = Node.new(Emp, :include => :job)
    @graph = Graph.new node
  end
  
  #
  # initialize test
  #
  
  def test_default_initialize
    assert_equal graph.node.aliases, graph.aliases
    assert_equal({:default => graph}, graph.subsets)
  end
  
  def test_initialize_may_define_new_aliases
    name_columns = %w{first_name last_name}
    
    graph = Graph.new(node, :aliases => {'name_only' => name_columns})
    assert_equal name_columns, graph.aliases['name_only']
  end
  
  def test_initialize_registers_subsets
    name_columns = %w{first_name last_name}
    
    graph = Graph.new(node, :subsets => {'name_only' => name_columns})
    assert_equal name_columns, graph.subsets['name_only'].paths
  end
  
  def test_initialize_may_unregister_the_default_subset
    graph = Graph.new(node, :subsets => {:default => nil})
    assert_equal({}, graph.subsets)
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
    assert_equal nil, graph.subsets[:type]
    
    graph.register(:type, %w{first_name last_name})
    assert_equal %w{first_name last_name}, graph.subsets[:type].paths
  end
  
  def test_register_returns_subset_graph
    subset = graph.register(:type, %w{first_name last_name})
    assert_equal Graph, subset.class
    assert_equal %w{first_name last_name}, subset.paths
  end
  
  def test_nil_paths_deletes_registered_type
    subset = graph.register(:type, %w{first_name last_name})
    assert_equal subset, graph.register(:type, nil)
    assert_equal nil, graph.subsets[:type]
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
    }, subset.paths
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
    }, subset.paths
  end
  
  #
  # subset test
  #
  
  def test_subset_returns_subset_registered_to_type
    subset = graph.register(:type, %w{first_name last_name})
    assert_equal subset, graph.subset(:type)
  end
  
  def test_subset_returns_default_subset_if_no_subset_is_registered_to_the_specified_type
    assert_equal nil, graph.subsets[:type]
    
    subset = graph.register(:default, %w{first_name last_name})
    assert_equal subset, graph.subset(:type)
  end
  
  def test_subset_raises_error_if_neither_type_nor_default_are_registered
    graph.register(:default, nil)
    assert_equal({}, graph.subsets)
    
    err = assert_raises(RuntimeError) { graph.subset(:type) }
    assert_equal 'no such subset: :type', err.message
  end
  
  #
  # validate test
  #
  
  def test_validate_returns_paths_if_the_paths_are_contained_by_the_subset_get_paths
    assert_equal %w{first_name last_name}, graph.validate(:default, %w{first_name last_name})
    assert_equal %w{first_name job.name last_name}, graph.validate(:default, %w{first_name job.name last_name})
  end
  
  def test_validate_raises_an_error_if_the_paths_are_not_contained_by_the_subset_get_paths
    graph.register(:names, %w{first_name last_name})
    
    err = assert_raises(DataGraph::InaccessiblePathError) { graph.validate(:names, %w{first_name salary job.name last_name}) }
    assert_equal 'inaccessible: ["salary", "job.name"]', err.message
  end
  
  #
  # validate_attrs test
  #
  
  def test_validate_attrs_returns_attrs_if_the_attrs_are_contained_by_the_subset_set_paths
    attrs = {
      'first_name' => 'John', 
      'last_name' => 'Doe'
    }
    
    assert_equal attrs, graph.validate_attrs(:default, attrs)
  end
  
  class NestJob < Job
    accepts_nested_attributes_for :employees
  end
  
  def test_validate_attrs_resolves_nested_attrs_if_possible
    graph = Graph.new Node.new(NestJob, :include => :employees)
    
    attrs = {
      'name' => 'Developer',
      'employees_attributes' => [
        {'first_name' => 'John'},
        {'last_name' => 'Doe', 'salary' => 1000}
      ]
    }
    assert_equal attrs, graph.validate_attrs(:default, attrs)
    
    attrs = {
      'name' => 'Developer',
      'employees_attributes' => {
        1 => {'first_name' => 'John'},
        2 => {'last_name' => 'Doe', 'salary' => 1000}
      }
    }
    assert_equal attrs, graph.validate_attrs(:default, attrs)
  end
  
  def test_validate_attrs_an_error_if_the_paths_are_not_contained_by_the_subset_set_paths
    graph.register(:names, %w{first_name last_name})
    
    err = assert_raises(DataGraph::InaccessiblePathError) do
      graph.validate_attrs(:names, {
        'first_name' => 'John', 
        'salary' => 1000, 
        'job' => {'name' => 'Developer'}
      })
    end
    
    assert_equal 'inaccessible: ["salary", "job.name"]', err.message
  end
end