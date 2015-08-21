module Maple::MapleTA
  module Orm
    class AssignmentQuestionGroup < ActiveRecord::Base
      include Maple::MapleTA::Orm

      self.table_name = 'assignment_question_group'

      belongs_to :assignment, :class_name => 'Maple::MapleTA::Orm::Assignment', :foreign_key => 'assignmentid'
      belongs_to :assignment_branch, :class_name => 'Maple::MapleTA::Orm::AssignmentBranch', :foreign_key => 'assignment_branch_id'
      has_many :assignment_question_group_maps, :class_name => 'Maple::MapleTA::Orm::AssignmentQuestionGroupMap', :foreign_key => 'groupid', :dependent => :destroy

      def is_question?
        questions_to_pick == 1 && assignment_question_group_maps.count <= 1
      end

    end
  end
end
