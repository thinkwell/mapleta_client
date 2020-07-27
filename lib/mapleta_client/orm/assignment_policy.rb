module Maple::MapleTA
  module Orm
    class AssignmentPolicy < Base

      self.primary_key = 'assignment_class_id'
      self.table_name = 'assignment_policy'

      belongs_to :assignment_class, :class_name => namespace('AssignmentClass'), :foreign_key => 'assignment_class_id'

    end
  end
end