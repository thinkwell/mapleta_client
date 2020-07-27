module Maple::MapleTA
  module Orm
    class Class < Base

      self.primary_key = 'cid'

      belongs_to :parent_class, :class_name => namespace('Class'), :primary_key => 'cid', :foreign_key => 'parent'
      has_many :children, :class_name => namespace('Class'), :primary_key => 'cid', :foreign_key => 'parent'
      has_many :assignments, :class_name => namespace('Assignment'), :foreign_key => 'classid'
      has_many :class_assignments, :class_name => namespace('AssignmentClass'), :foreign_key => 'classid'

    end
  end
end