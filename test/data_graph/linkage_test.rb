require File.expand_path('../../test_helper', __FILE__)
require 'data_graph/linkage'

class LinkageTest < Test::Unit::TestCase
  Linkage = DataGraph::Linkage
  include DatabaseTest
  
  def linkage(model, assoc_name, options={})
    Linkage.new(model.reflect_on_association(assoc_name), options)
  end
  
  #
  # belongs_to test
  #
  
  class BtOne < ActiveRecord::Base
    set_table_name 'one'
    belongs_to :bt, :class_name => 'LinkageTest::BtTwo', :foreign_key => :two_id
  end

  class BtTwo < ActiveRecord::Base
    set_table_name 'two'
  end
  
  def test_link_for_bt
    fixture %q{
      create table one (id number, two_id number, primary key (id));
      create table two (id number, primary key (id));
      
      insert into one values (1, 10);
      insert into one values (2, 20);
      insert into two values (10);
      insert into two values (30);
    }, %q{
      drop table two;
      drop table one;
    }
    
    a, b = BtOne.find(1), BtOne.find(2)
    assert_equal nil, a.loaded_bt?
    assert_equal nil, b.loaded_bt?
    
    linkage(BtOne, :bt).link([a,b])
    
    assert_equal true, a.loaded_bt?
    assert_equal nil, b.loaded_bt?
    
    assert_equal 10, a.bt.id
    assert_equal nil, b.bt
  end
  
  #
  # has_many test
  #
  
  class HmOne < ActiveRecord::Base
    set_table_name 'one'
    has_many :hm, :class_name => 'LinkageTest::HmTwo', :foreign_key => :one_id
  end

  class HmTwo < ActiveRecord::Base
    set_table_name 'two'
  end
  
  def test_link_for_hm
    fixture %q{
      create table one (id number, primary key (id));
      create table two (id number, one_id number, primary key (id));
      
      insert into one values (1);
      insert into one values (2);
      insert into two values (10, 1);
      insert into two values (20, 1);
      insert into two values (30, 3);
    }, %q{
      drop table two;
      drop table one;
    }
    
    a, b = HmOne.find(1), HmOne.find(2)
    assert_equal false, a.hm.loaded?
    assert_equal false, b.hm.loaded?
    
    linkage(HmOne, :hm).link([a,b])
    
    assert_equal true, a.hm.loaded?
    assert_equal true, b.hm.loaded?
    
    assert_equal([10, 20], a.hm.collect {|two| two.id })
    assert_equal [], b.hm
  end
  
  class HmtOne < ActiveRecord::Base
    set_table_name 'one'
    has_many :hm, :class_name => 'LinkageTest::HmtTwo', :foreign_key => :one_id
    has_many :hmt, :through => :hm, :source => :bt
  end

  class HmtTwo < ActiveRecord::Base
    set_table_name 'two'
    belongs_to :bt, :class_name => 'LinkageTest::HmtThree', :foreign_key => :three_id
  end
  
  class HmtThree < ActiveRecord::Base
    set_table_name 'three'
  end
  
  def test_link_for_hmt
    fixture %q{
      create table one (id number, primary key (id));
      create table two (id number, one_id number, three_id number, primary key (id));
      create table three (id number, primary key (id));
      
      insert into one values (1);
      insert into one values (2);
      insert into two values (100, 1, 10);
      insert into two values (200, 1, 20);
      insert into two values (300, 3, 30);
      insert into three values (10);
      insert into three values (20);
      insert into three values (30);
    }, %q{
      drop table three;
      drop table two;
      drop table one;
    }
    
    a, b = HmtOne.find(1), HmtOne.find(2)
    assert_equal false, a.hmt.loaded?
    assert_equal false, b.hmt.loaded?
    
    linkage(HmtOne, :hmt).link([a,b])
    
    assert_equal true, a.hmt.loaded?
    assert_equal true, b.hmt.loaded?
    
    assert_equal([10, 20], a.hmt.collect {|three| three.id })
    assert_equal [], b.hmt
  end
  
  class CpkHmtOne < ActiveRecord::Base
    set_table_name 'one'
    has_many :hm, :class_name => 'LinkageTest::CpkHmtTwo', :foreign_key => :one_id
    has_many :hmt, :through => :hm, :source => :bt
  end

  class CpkHmtTwo < ActiveRecord::Base
    set_table_name 'two'
    set_primary_keys 'one_id', 'three_a', 'three_b'
    belongs_to :bt, :class_name => 'LinkageTest::CpkHmtThree', :foreign_key => [:three_a, :three_b]
  end
  
  class CpkHmtThree < ActiveRecord::Base
    set_table_name 'three'
    set_primary_keys 'a', 'b'
  end
  
  def test_link_for_cpk_hmt
    fixture %q{
      create table one (
        id number, 
        primary key (id)
      );
      create table two (
        one_id number, 
        three_a number, 
        three_b number, 
        primary key (one_id, three_a, three_b)
      );
      create table three (
        a number, 
        b number, 
        primary key (a, b)
      );
      
      insert into one values (1);
      insert into one values (2);
      insert into two values (1, 10, 100);
      insert into two values (1, 20, 100);
      insert into two values (3, 30, 100);
      insert into three values (10, 100);
      insert into three values (20, 100);
      insert into three values (30, 100);
    }, %q{
      drop table three;
      drop table two;
      drop table one;
    }
    
    a, b = CpkHmtOne.find(1), CpkHmtOne.find(2)
    assert_equal false, a.hmt.loaded?
    assert_equal false, b.hmt.loaded?
    
    linkage(CpkHmtOne, :hmt).link([a,b])
    
    assert_equal true, a.hmt.loaded?
    assert_equal true, b.hmt.loaded?
    
    assert_equal([10, 20], a.hmt.collect {|three| three.a })
    assert_equal [], b.hmt
  end
  
  #
  # has_one test
  #
  
  class HoOne < ActiveRecord::Base
    set_table_name 'one'
    has_one :ho, :class_name => 'LinkageTest::HoTwo', :foreign_key => :one_id
  end

  class HoTwo < ActiveRecord::Base
    set_table_name 'two'
  end
  
  def test_link_for_ho
    fixture %q{
      create table one (id number, primary key (id));
      create table two (id number, one_id number, primary key (id));
      
      insert into one values (1);
      insert into one values (2);
      insert into two values (10, 1);
      insert into two values (30, 3);
    }, %q{
      drop table two;
      drop table one;
    }
    
    a, b = HoOne.find(1), HoOne.find(2)
    assert_equal nil, a.loaded_ho?
    assert_equal nil, b.loaded_ho?
    
    linkage(HoOne, :ho).link([a,b])
    
    assert_equal true, a.loaded_ho?
    assert_equal true, b.loaded_ho?
    
    assert_equal 10, a.ho.id
    assert_equal nil, b.ho
  end
  
  class HotOne < ActiveRecord::Base
    set_table_name 'one'
    has_many :hm, :class_name => 'LinkageTest::HotTwo', :foreign_key => :one_id
    has_one :hot, :through => :hm, :source => :bt
  end

  class HotTwo < ActiveRecord::Base
    set_table_name 'two'
    belongs_to :bt, :class_name => 'LinkageTest::HotThree', :foreign_key => :three_id
  end
  
  class HotThree < ActiveRecord::Base
    set_table_name 'three'
  end
  
  def test_link_for_hot
    fixture %q{
      create table one (id number, primary key (id));
      create table two (id number, one_id number, three_id number, primary key (id));
      create table three (id number, primary key (id));
      
      insert into one values (1);
      insert into one values (2);
      insert into two values (100, 1, 10);
      insert into two values (300, 3, 30);
      insert into three values (10);
      insert into three values (30);
    }, %q{
      drop table three;
      drop table two;
      drop table one;
    }
    
    a, b = HotOne.find(1), HotOne.find(2)
    assert_equal nil, a.loaded_hot?
    assert_equal nil, b.loaded_hot?
    
    linkage(HotOne, :hot).link([a,b])
    
    assert_equal true, a.loaded_hot?
    assert_equal true, b.loaded_hot?
    
    assert_equal 10, a.hot.id
    assert_equal nil, b.hot
  end
end