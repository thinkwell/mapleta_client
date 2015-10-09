module Maple::MapleTA
  module Orm
    class AssignmentQuestionGroupMap < Base

      self.table_name = 'assignment_question_group_map'

      belongs_to :assignment_question_group, :class_name => namespace('AssignmentQuestionGroup'), :foreign_key => 'groupid'
      belongs_to :question, :class_name => namespace('Question'), :foreign_key => 'questionid'

    end
  end
end
