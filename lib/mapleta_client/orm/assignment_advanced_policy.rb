# Use and_id to group advanced policies into AND conditions. Use or_id to order OR conditions within groups.

module Maple::MapleTA
  module Orm
    class AssignmentAdvancedPolicy < Base

      set_primary_key 'assignment_class_id'
      self.table_name = 'assignment_advanced_policy'

      belongs_to :assignment_class, :class_name => namespace('AssignmentClass'), :foreign_key => 'assignment_class_id'
      belongs_to :assignment, :class_name => namespace('Assignment'), :foreign_key => 'assignment_id'

    end
  end
end