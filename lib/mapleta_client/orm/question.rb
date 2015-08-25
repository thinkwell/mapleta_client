module Maple::MapleTA
  module Orm
    class Question < Base

      self.table_name = 'question'

      has_many :assignment_question_group_maps, :class_name => 'Maple::MapleTA::Orm::AssignmentQuestionGroupMap', :foreign_key => 'questionid'

    end
  end
end
