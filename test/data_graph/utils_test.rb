require File.expand_path('../../test_helper', __FILE__)
require 'data_graph/utils'
require 'job'

class UtilsTest < Test::Unit::TestCase
  include DataGraph::Utils
  include DatabaseTest
  
  class One < ActiveRecord::Base
    set_table_name 'one'
    set_primary_key :one
  
    belongs_to :bt, :class_name => 'UtilsTest::Two', :foreign_key => :x
    has_many :hm, :class_name => 'UtilsTest::Two', :foreign_key => :y
    has_one :ho, :class_name => 'UtilsTest::Two', :foreign_key => :z
  end

  class Two < ActiveRecord::Base
    set_table_name 'two'
    set_primary_key :two
  end
  
  class CpkOne < ActiveRecord::Base
    set_table_name 'cpk_one'
    set_primary_keys :one_a, :one_b
  
    belongs_to :bt, :class_name => 'UtilsTest::CpkTwo', :foreign_key => [:x_one, :x_two]
    has_many :hm, :class_name => 'UtilsTest::CpkTwo', :foreign_key => [:y_one, :y_two]
    has_one :ho, :class_name => 'UtilsTest::CpkTwo', :foreign_key => [:z_one, :z_two]
  end

  class CpkTwo < ActiveRecord::Base
    set_table_name 'cpk_two'
    set_primary_keys :two_a, :two_b
  end
  
  #
  # foreign_key test
  #
  
  def test_foreign_key_determines_foreign_key_for_belongs_to
    assoc = One.reflect_on_association(:bt)
    assert_equal ['x'], foreign_key(assoc)
  end
  
  def test_foreign_key_determines_foreign_key_for_has_x
    assoc = One.reflect_on_association(:hm)
    assert_equal ['y'], foreign_key(assoc)
    
    assoc = One.reflect_on_association(:ho)
    assert_equal ['z'], foreign_key(assoc)
  end
  
  def test_foreign_key_determines_foreign_key_for_cpk_belongs_to
    assoc = CpkOne.reflect_on_association(:bt)
    assert_equal ['x_one', 'x_two'], foreign_key(assoc)
  end
  
  def test_foreign_key_determines_foreign_key_for_cpk_has_x
    assoc = CpkOne.reflect_on_association(:hm)
    assert_equal ['y_one', 'y_two'], foreign_key(assoc)
    
    assoc = CpkOne.reflect_on_association(:ho)
    assert_equal ['z_one', 'z_two'], foreign_key(assoc)
  end
  
  #
  # reference_key test
  #
  
  def test_reference_key_determines_reference_key_for_belongs_to
    assoc = One.reflect_on_association(:bt)
    assert_equal ['two'], reference_key(assoc)
  end
  
  def test_reference_key_determines_reference_key_for_has_x
    assoc = One.reflect_on_association(:hm)
    assert_equal ['one'], reference_key(assoc)
    
    assoc = One.reflect_on_association(:ho)
    assert_equal ['one'], reference_key(assoc)
  end
  
  def test_reference_key_determines_reference_key_for_cpk_belongs_to
    assoc = CpkOne.reflect_on_association(:bt)
    assert_equal ['two_a', 'two_b'], reference_key(assoc)
  end
  
  def test_reference_key_determines_reference_key_for_cpk_has_x
    assoc = CpkOne.reflect_on_association(:hm)
    assert_equal ['one_a', 'one_b'], reference_key(assoc)
    
    assoc = CpkOne.reflect_on_association(:ho)
    assert_equal ['one_a', 'one_b'], reference_key(assoc)
  end
  
  #
  # patherize_attrs test
  #
  
  def test_patherize_attrs_returns_an_array_of_paths_described_by_a_hash
    assert_equal ['a', 'b', 'c.d', 'e.f', 'e.g'], patherize_attrs(
      'a' => 1,
      'b' => 2,
      'c' => {'d' => 3},
      'e' => [{'f' => 4}, {'g' => 5}]
    ).sort
  end
  
  def test_patherize_attrs_allows_symbol_keys
    assert_equal ['a', 'b', 'c.d'], patherize_attrs(
      :a => 1,
      :b => 2,
      :c => {:d => 3}
    ).sort
  end
  
  def test_patherize_attrs_skips_over_nested_paths
    attrs = {
      :a => 1,
      :b => 2,
      :c => {
        '1' => {:d => 3},
        '2' => {:e => 4},
        '3' => {
          :f => {
            '1' => {:g => 5},
            '2' => {:h => 6}
          }
        }
      }
    }
    
    nest_paths = %w{
      c
      c.f
    }
    
    assert_equal %w{
      a
      b
      c.d
      c.e
      c.f.g
      c.f.h
    }, patherize_attrs(attrs, nest_paths).sort
  end
  
  def test_patherize_attrs_also_works_with_array_of_nested_paths
    attrs = {
      :a => 1,
      :b => 2,
      :c => [
        {:d => 3},
        {:e => 4},
        {
          :f => [
            {:g => 5},
            {:h => 6}
          ]
        }
      ]
    }
    
    nest_paths = %w{
      c
      c.f
    }
    
    assert_equal %w{
      a
      b
      c.d
      c.e
      c.f.g
      c.f.h
    }, patherize_attrs(attrs, nest_paths).sort
  end
end