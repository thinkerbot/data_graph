require 'job'
require 'dept'

class Emp < ActiveRecord::Base
  belongs_to :department, :class_name => 'Dept', :foreign_key => 'dept_id'
  belongs_to :job,  :class_name => 'Job'
  belongs_to :manager, :class_name => 'Emp', :foreign_key => 'manager_id'
  has_many   :workers, :class_name => 'Emp', :foreign_key => 'manager_id'
end
