module Maple::MapleTA
  module Orm
    class AssignmentMasteryPenalty < Base

      set_primary_key 'assignment_class_id'
      self.table_name = 'assignment_mastery_penalty'

      belongs_to :assignment_class, :class_name => namespace('AssignmentClass'), :foreign_key => 'assignment_class_id'

    end
  end
end