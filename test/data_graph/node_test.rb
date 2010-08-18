require File.expand_path('../../test_helper', __FILE__)
require 'data_graph/node'
require 'emp'
require 'product'

class NodeTest < Test::Unit::TestCase
  Node = DataGraph::Node
  include DatabaseTest
  
  attr_reader :node
  
  def setup
    super
    @node = Node.new(Job, :methods => [:object_id], :include => :employees)
  end
  
  #
  # initialize test
  #
  
  def test_default_initialize
    node = Node.new(Job)
    
    assert_equal Job, node.model
    assert_equal Job.column_names, node.column_names
    assert_equal [], node.method_names
    assert_equal [], node.associations
  end
  
  def test_initialize_sets_column_names_as_specified_by_only
    node = Node.new(Job, :only => [:name])
    assert_equal %w{name}, node.column_names
  end
  
  def test_initialize_sets_column_names_as_specified_by_except
    node = Node.new(Job, :except => [:name])
    assert_equal %w{
      id
    }, node.column_names
  end
  
  def test_initialize_ignores_non_existant_column_names
    node = Node.new(Job, :only => ['missing'])
    assert_equal %w{}, node.column_names
    
    node = Node.new(Job, :except => ['missing'])
    assert_equal %w{
      id
      name
    }, node.column_names
  end
  
  def test_initialize_sets_method_names_as_specified
    node = Node.new(Job, :methods => [:object_id])
    assert_equal %w{object_id}, node.method_names
  end
  
  def test_initialize_allows_non_existant_methods
    assert_equal false, Job.instance_methods.include?('missing')
    node = Node.new(Job, :methods => [:missing])
    assert_equal %w{missing}, node.method_names
  end
  
  def test_initialize_sets_associations_as_specified_by_include
    node = Node.new(Emp, :include => [:job, :department])
    assert_equal %w{job department}.sort, node.associations.sort
  end
  
  def test_initialize_accepts_single_value_include
    node = Node.new(Emp, :include => :job)
    assert_equal %w{job}, node.associations
  end
  
  def test_initialize_recursively_resolves_associations
    node = Node.new(
      Emp, 
      :include => {
        :job => {
          :only => ['name'],
          :include => {
            :employees => {
              :only => ['first_name', 'last_name']
            }
          }
        }
      }
    )
    
    assert_equal Emp, node.model
    assert_equal Emp.column_names, node.column_names
    assert_equal %w{job}, node.associations
    
    node = node['job']
    assert_equal Job, node.model
    assert_equal %w{name}, node.column_names
    assert_equal %w{employees}, node.associations
    
    node = node['employees']
    assert_equal Emp, node.model
    assert_equal %w{first_name last_name}, node.column_names
    assert_equal %w{}, node.associations
  end
  
  def test_initialize_ignores_missing_associations
    node = Node.new(Job, :include => :missing)
    assert_equal %w{}, node.associations
  end
  
  def test_initialize_sets_always_columns_to_primary_key_columns
    node = Node.new(Emp)
    assert_equal %w{
      id
    }, node.always_columns
  end
  
  def test_initialize_appends_any_always_columns_specified_in_options
    node = Node.new(Emp, :always => %w{first_name last_name})
    assert_equal %w{
      id
      first_name
      last_name
    }, node.always_columns
  end
  
  def test_initialize_raises_error_for_non_hash_inputs
    err = assert_raises(RuntimeError) { Node.new(Job, []) }
    assert_equal "not a hash: []", err.message
  end
  
  def test_initialize_raises_error_for_only_and_except
    node = {:only => ['name'], :except => ['id']}
    err = assert_raises(RuntimeError) { Node.new(Job, node) }
    assert_equal "only and except are both specified: #{node.inspect}", err.message
  end
  
  class DefineAttributeMethodsClass < ActiveRecord::Base
    set_table_name 'jobs'
  end
  
  def test_initialize_define_attribute_methods
    assert_equal false, DefineAttributeMethodsClass.generated_methods?
    Node.new(DefineAttributeMethodsClass)
    assert_equal true, DefineAttributeMethodsClass.generated_methods?
  end
  
  #
  # get_paths test
  #
  
  def test_get_paths_returns_all_accessible_paths
    expected = %w{
      id
      name
      object_id
      employees
      employees.id
      employees.first_name
      employees.last_name
      employees.job_id
      employees.dept_id
      employees.manager_id
      employees.salary
    }
    
    assert_equal expected, node.get_paths
  end
  
  def test_get_paths_always_includes_primary_keys
    node.only! %w{
      name
      employees.first_name
      employees.last_name
      employees.job_id
    }
    
    assert_equal %w{
      id
      name
      employees
      employees.id
      employees.first_name
      employees.last_name
      employees.job_id
    }, node.get_paths
  end
  
  def test_get_paths_always_includes_association_keys
    node.only! %w{
      name
      employees.first_name
      employees.last_name
    }
    
    assert_equal %w{
      id
      name
      employees
      employees.id
      employees.first_name
      employees.last_name
      employees.job_id
    }, node.get_paths
  end
  
  #
  # set_paths test
  #
  
  def test_set_paths_returns_column_names_and_methods
    assert_equal %w{
      id
      name
      object_id
    }, node.set_paths
  end
  
  def test_set_paths_always_includes_primary_key
    node.only! %w{name}
    
    assert_equal %w{
      id
      name
    }, node.set_paths
  end
  
  class NestedAttributesEmp < Emp
    accepts_nested_attributes_for :job
  end
  
  def test_set_paths_adds_paths_for_associations_when_model_accepts_nested_attributes
    node = Node.new(
      NestedAttributesEmp, 
      :only => %w{first_name last_name}, 
      :include => [:job, :department]
    )
    
    expected = %w{
      id
      first_name
      last_name
      job_attributes.id
      job_attributes.name
      job_attributes._destroy
      job_attributes._delete
    }
    
    assert_equal expected, node.set_paths
  end
  
  #
  # scope test
  #
  
  def test_scope_sets_select_to_column_names
    node = Node.new(Job, :only => %w{id name})
    assert_equal 'id,name', node.scope[:select]
  end
  
  def test_scope_adds_primary_key_to_select
    node = Node.new(Job, :only => %w{name})
    assert_equal 'name,id', node.scope[:select]
  end
  
  def test_scope_appends_column_names_to_existing_select
    node = Node.new(Job, :only => %w{id name})
    assert_equal 'a,upper(b),id,name', node.scope(:select => 'a,upper(b)')[:select]
  end
  
  def test_scope_appends_columns_used_by_linkages
    node = Node.new(Emp, :only => %w{id}, :include => :job)
    assert_equal 'id,job_id', node.scope[:select]
  end
  
  #
  # find test
  #
  
  def test_node_loads_only_included_attributes
    emp = Node.new(Emp, :include => {:job => {:only => [:id]}}).find(:first)
    assert_equal 1, emp.job.id
    assert_raises(ActiveRecord::MissingAttributeError) { emp.job.name }
  end
  
  def test_find_loads_unique_records_for_hmt
    job = Node.new(Job, :include => :departments).find(4)
    
    departments = job.departments.collect {|dept| dept.name }
    assert_equal %w{Research Sales Accounting}.sort, departments.sort
  end
  
  def test_find_all_loads_unique_records_for_hmt
    jobs = Node.new(Job, :include => :departments).find(:all)
    depts = jobs.collect {|job| job.departments.collect {|dept| dept.name} }
    
    assert_equal [
      ["Accounting"], 
      ["Research", "Sales", "Accounting"], 
      ["Research"], 
      ["Research", "Sales", "Accounting"], 
      ["Sales"]
    ], depts
  end
  
  def test_find_marks_associations_as_loaded_even_when_there_is_no_associated_data
    transaction do
      job_id = Job.create(:name => 'Developer').id
      job = Node.new(Job, :include => {:employees => {}}).find(job_id)
      assert_equal true, job.employees.loaded?
    end
  end
  
  def test_find_always_loads_always_columns
    emp = Node.new(Emp, :only => [], :always => %w{first_name}).find(:first)
    assert_equal 1, emp.id
    assert_equal 'Kim', emp.first_name
    assert_raises(ActiveRecord::MissingAttributeError) { emp.last_name }
  end
  
  #
  # cpk hmt test
  #
  
  def test_find_for_cpk_hmt
    tariffs = Product.find(1).tariffs.collect {|tariff| tariff.amount }
    assert_equal [50, 0], tariffs
    
    tariffs = Product.data_graph(:include => :tariffs).find(1).tariffs.collect {|tariff| tariff.amount }
    assert_equal [50, 0], tariffs
  end
  
  #
  # options test
  #
  
  def test_options_returns_options_as_for_serialization
    expected = {
      :only => %w{
        id
        name
      },
      :methods => %w{
        object_id
      },
      :include => {
        :employees => {
          :only => %w{
            id
            first_name
            last_name
            job_id
            dept_id
            manager_id
            salary
          },
          :methods => [],
          :include => {}
        }
      }
    }
    
    assert_equal expected, node.options
  end
  
  #
  # aliases test
  #
  
  def test_aliases_returns_hash_of_default_splat_aliases
    expected = {
      '*' => %w{
        id
        name
      },
      'employees.*' => %w{
        employees.id
        employees.first_name
        employees.last_name
        employees.job_id
        employees.dept_id
        employees.manager_id
        employees.salary
      }
    }
    
    assert_equal expected, node.aliases
  end
  
  def test_aliases_works_for_has_many_through
    node = Node.new(Job, :include => :departments)
    
    expected = {
      '*' => %w{
        id
        name
      },
      'departments.*' => %w{
        departments.id
        departments.name
        departments.city
        departments.state
      }
    }
    
    assert_equal expected, node.aliases
  end
  
  #
  # only! test
  #
  
  def test_only_bang_selects_intersection_the_specified_paths_and_self
    node.only! %w{
      id 
      name 
      object_id
      employees.first_name 
      employees.last_name
    }
    
    assert_equal %w{
      id
      name
      object_id
      employees.first_name
      employees.last_name
    }, node.paths
  end
  
  def test_only_bang_selects_associations
    node = Node.new(Emp, 
      :include => {
        :job => {
          :only => ['name'], 
          :methods => ['object_id']
        },
        :department => {}
    })
    
    node.only! %w{job}
    assert_equal %w{job.name job.object_id}, node.paths
  end
  
  def test_only_bang_selects_hmt_associations
    node = Node.new(Job, :include => {:departments => {:only => %w{name city state}}})
    
    node.only! %w{departments}
    assert_equal %w{departments.name departments.city departments.state}, node.paths
  end
  
  def test_only_bang_selects_specific_paths_on_hmt_associations
    node = Node.new(Job, :include => {:departments => {:only => %w{name city state}}})
    node.only! %w{departments.name}
    assert_equal %w{departments.name}, node.paths
  end
  
  def test_only_bang_ignores_duplicates
    node.only! %w{
      name
      name
      object_id
      object_id
    }
    
    assert_equal %w{
      name object_id
    }, node.paths
  end
  
  def test_only_bang_preserves_always_columns
    node = Node.new(Dept, :always => %w{name})
    
    node.only! %w{
      city
    }
    
    assert_equal %w{
      city
    }, node.column_names
    
    assert_equal %w{
      id
      name
    }, node.always_columns
  end
  
  #
  # only test
  #
  
  def test_only_returns_new_node_with_only_specified_paths
    new_node = node.only %w{name}
    assert new_node.object_id != node.object_id
    assert_equal %w{name}, new_node.paths
  end
  
  def test_only_does_not_affect_self
    orig_paths = node.paths
    node.only %w{name}
    assert_equal orig_paths, node.paths
  end
  
  #
  # except! test
  #
  
  def test_except_bang_filters_specified_paths
    node.except! %w{
      name
      object_id
      employees.first_name
      employees.last_name
    }
    
    assert_equal %w{
      id
      employees.id
      employees.job_id
      employees.dept_id
      employees.manager_id
      employees.salary
    }, node.paths
  end
  
  def test_except_bang_removes_associations
    node.except! %w{employees}
    
    assert_equal %w{
      id
      name
      object_id
    }, node.paths
  end
  
  def test_except_bang_removes_hmt_associations
    node = Node.new(Job, :only => %w{id name}, :include => {:departments => {:only => %w{name city state}}})
    
    node.except! %w{
      departments
    }
    
    assert_equal %w{
      id
      name
    }, node.paths
  end
  
  def test_except_bang_removes_specific_paths_on_hmt_associations
    node = Node.new(Job, :only => %w{id name}, :include => {:departments => {:only => %w{name city state}}})
    node.except! %w{
      departments.name
    }
    
    assert_equal %w{
      id
      name
      departments.city
      departments.state
    }, node.paths
  end
  
  def test_except_bang_preserves_always_columns
    node = Node.new(Job, :always => %w{name})
    
    node.except! %w{
      name
    }
    
    assert_equal %w{
      id
    }, node.column_names
    
    assert_equal %w{
      id
      name
    }, node.always_columns
  end
  
  #
  # except test
  #
  
  def test_except_returns_new_node_without_specified_paths
    new_node = node.except %w{
      name
      object_id
      employees.first_name
      employees.last_name
    }
    
    assert new_node.object_id != node.object_id
    
    assert_equal %w{
      id
      employees.id
      employees.job_id
      employees.dept_id
      employees.manager_id
      employees.salary
    }, new_node.paths
  end
  
  def test_except_does_not_affect_self
    orig_paths = node.paths
    node.except %w{name}
    assert_equal orig_paths, node.paths
  end
end