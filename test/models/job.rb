require 'emp'

class Job < ActiveRecord::Base
  has_many :employees, :class_name => 'Emp'
  has_many :departments, :through => :employees
end
