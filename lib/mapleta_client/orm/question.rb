module Maple::MapleTA
  module Orm
    class Question < Base

      self.table_name = 'question'

      has_many :assignment_question_group_maps, :class_name => namespace('AssignmentQuestionGroupMap'), :foreign_key => 'questionid'
      belongs_to :question_header, :class_name => namespace('QuestionHeader'), :primary_key => 'uid', :foreign_key => 'uid'

      def latest_revision_id
        latestrevision || self.id
      end

      def is_latest_revision?
        !latestrevision
      end

    end
  end
end
