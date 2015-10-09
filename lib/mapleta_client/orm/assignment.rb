module Maple::MapleTA
  module Orm
    class Assignment < Base

      set_primary_key 'id'
      self.table_name = 'assignment'

      belongs_to :parent_class, :class_name => namespace('Class'), :foreign_key => 'classid'
      has_many :assignment_branches, :class_name => namespace('AssignmentBranch'), :foreign_key => 'assignmentid', :dependent => :destroy
      has_many :assignment_question_groups, :class_name => namespace('AssignmentQuestionGroup'), :foreign_key => 'assignmentid', :dependent => :destroy
      has_many :advanced_policy, :class_name => namespace('AssignmentAdvancedPolicy'), :foreign_key => 'assignment_id', :dependent => :destroy
      has_many :assignment_classes, :class_name => namespace('AssignmentClass'), :foreign_key => 'assignmentid', :dependent => :destroy
      has_many :testrecords, :class_name => namespace('Testrecord'), :foreign_key => 'assignmentid', :dependent => :destroy
      has_many :student_assignment_permissions, :class_name => namespace('StudentAssignmentPermission'), :foreign_key => 'assignmentid', :dependent => :destroy

      def question_groups; self.assignment_question_groups; end

      def remove_all_questions_and_groups
        self.assignment_question_groups.each{|g| g.destroy}
      end

      def add_groups_and_questions(groups)
        remove_all_questions_and_groups

        groups.each_with_index do |hash, group_order_indx|
          group, questions = hash.first

          aqg = AssignmentQuestionGroup.new
          aqg.name = group["name"]
          aqg.questions_to_pick = group["questions_to_pick"]
          aqg.order_id = group["order_id"]
          #aqg.order_id = group_order_indx
          aqg.weighting = group["weighting"]
          aqg.assignmentid = self.id
          aqg.save
          questions.each_with_index do |params, question_order_indx|
            q = AssignmentQuestionGroupMap.new
            q.groupid = aqg.id
            q.questionid = params["id"].to_i
            q.question_uid = Question.find(params["id"].to_i).uid
            q.order_id = params["order_id"].to_i
            #q.order_id = question_order_indx
            q.save
          end
        end

      end

    end
  end
end
