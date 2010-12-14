require File.expand_path('../test_helper', __FILE__)
require 'data_graph'

class DataGraphTest < Test::Unit::TestCase
  include DatabaseTest
  
  #
  # Model.data_graph test
  #

  def test_data_graph_returns_a_graph_for_self
    dg = Job.data_graph
    assert_equal DataGraph::Graph, dg.class
  end
  
  def test_data_graphs_can_be_loaded_with_a_to_json_options_hash
    opts = {
      :only => ['first_name', 'last_name'], 
      :include => {
        :job => {
          :only => ['name']
        }
      }
    }
    
    json = Emp.data_graph(opts).find(:first).to_json(opts)
    
    assert_equal({
      'first_name' => 'Kim',
      'last_name'  => 'King',
      'job' => {'name' => 'President'}
    }, ActiveSupport::JSON.decode(json))
  end
  
  class CpkOne < ActiveRecord::Base
    set_table_name 'one'
    set_primary_keys :a, :b
    
    belongs_to :cpk_two, :primary_key => :q, :foreign_key => :p
    has_many :cpk_twos, :foreign_key => [:x, :y]
  end

  class CpkTwo < ActiveRecord::Base
    set_table_name 'two'
    set_primary_keys :q
  end

  def test_data_graphs_can_load_cpk_associations
    fixture %q{
      create table one (
        a number, 
        b number, 
        p number,
        primary key(a, b)
      );
      
      create table two (
        x number, 
        y number, 
        q number,
        primary key(q)
      );
      
      insert into one values (1, 1, 1);
      insert into one values (1, 2, 2);
      insert into one values (2, 1, 3);
      
      insert into two values (1, 1, 3);
      insert into two values (1, 2, 2);
      insert into two values (2, 1, 1);
    }, %q{
      drop table two;
      drop table one;
    }

    opts = {
      :only => ['p'], 
      :include => {
        :cpk_two => {
          :only => ['q']
        },
        :cpk_twos => {
          :only => ['q']
        }
      }
    }
    
    json = CpkOne.data_graph(opts).find(:all).to_json(opts)
    
    assert_equal [
      { 
        'p' => 1,
        'cpk_two'  => {'q' => 1},
        'cpk_twos' => [{'q' => 3}]
      },{
        'p' => 2,
        'cpk_two'  => {'q' => 2},
        'cpk_twos' => [{'q' => 2}]
      },{
        'p' => 3,
        'cpk_two'  => {'q' => 3},
        'cpk_twos' => [{'q' => 1}]
      }
    ], ActiveSupport::JSON.decode(json)
  end
  
  def test_data_graphs_return_parents_if_child_table_has_no_entries
    fixture %q{
      create table one (
        a number, 
        b number, 
        p number,
        primary key(a, b)
      );
      
      create table two (
        x number, 
        y number, 
        q number,
        primary key(q)
      );
      
      insert into one values (1, 1, 1);
      insert into one values (1, 2, 2);
      insert into one values (2, 1, 3);
    }, %q{
      drop table two;
      drop table one;
    }

    opts = {
      :only => ['p'], 
      :include => {
        :cpk_two => {
          :only => ['q']
        },
        :cpk_twos => {
          :only => ['q']
        }
      }
    }
    
    json = CpkOne.data_graph(opts).find(:all).to_json(opts)
    
    assert_equal [
      { 'p' => 1, 'cpk_twos' => []},
      { 'p' => 2, 'cpk_twos' => []},
      { 'p' => 3, 'cpk_twos' => []}
    ], ActiveSupport::JSON.decode(json)
  end
  
  def test_data_graphs_return_no_results_if_parent_table_has_no_entries
    fixture %q{
      create table one (
        a number, 
        b number, 
        p number,
        primary key(a, b)
      );
      
      create table two (
        x number, 
        y number, 
        q number,
        primary key(q)
      );
      
      insert into two values (1, 1, 3);
      insert into two values (1, 2, 2);
      insert into two values (2, 1, 1);
    }, %q{
      drop table two;
      drop table one;
    }

    opts = {
      :only => ['p'], 
      :include => {
        :cpk_two => {
          :only => ['q']
        },
        :cpk_twos => {
          :only => ['q']
        }
      }
    }
    
    assert_equal "[]", CpkOne.data_graph(opts).find(:all).to_json(opts)
  end
end