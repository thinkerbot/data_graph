require 'emp'

class Dept < ActiveRecord::Base
  has_many :employees, :class_name => 'Emp', :foreign_key => 'dept_id'
end
