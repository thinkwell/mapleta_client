module Maple::MapleTA
  module Orm
    class AssignmentBranch < ActiveRecord::Base
      include Maple::MapleTA::Orm

      set_primary_key 'id'
      self.table_name = 'assignment_branch'

      belongs_to :assignment, :class_name => 'Maple::MapleTA::Orm::Assignment', :foreign_key => 'assignmentid'
      has_many :assignment_question_groups, :class_name => 'Maple::MapleTA::Orm::AssignmentQuestionGroup', :foreign_key => 'assignment_branch_id'

    end
  end
end
