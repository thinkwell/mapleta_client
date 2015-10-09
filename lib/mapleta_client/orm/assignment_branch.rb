module Maple::MapleTA
  module Orm
    class AssignmentBranch < Base

      set_primary_key 'id'
      self.table_name = 'assignment_branch'

      belongs_to :assignment, :class_name => namespace('Assignment'), :foreign_key => 'assignmentid'
      has_many :assignment_question_groups, :class_name => namespace('AssignmentQuestionGroup'), :foreign_key => 'assignment_branch_id', :dependent => :destroy

    end
  end
end
