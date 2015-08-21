module Maple::MapleTA
  module Orm
    class AssignmentClass < ActiveRecord::Base
      include Maple::MapleTA::Orm

      self.table_name = 'assignment_class'

      belongs_to :parent_class, :class_name => 'Maple::MapleTA::Orm::Class', :foreign_key => 'classid'
      belongs_to :assignment, :class_name => 'Maple::MapleTA::Orm::Assignment', :foreign_key => 'assignmentid'
      has_one :policy, :class_name => 'Maple::MapleTA::Orm::AssignmentPolicy', :foreign_key => 'assignment_class_id'
      has_many :advanced_policies, :class_name => 'Maple::MapleTA::Orm::AssignmentAdvancedPolicy', :foreign_key => 'assignment_class_id'

      def attempts_allowed
        retake_policy.keyword if retake_policy
      end

      def retake_policy
        @retake_policy ||= self.advanced_policies.select{|p| p.assignment_id == self.assignmentid}.last
      end

      def attempts_allowed=(attempts)
        if retake_policy
          if attempts.blank? || attempts == 0
            retake_policy.delete
          else
            retake_policy.keyword = attempts
            retake_policy.save
          end
        elsif !attempts.blank?
          aap = AssignmentAdvancedPolicy.new
          aap.assignment_class_id = self.id
          aap.assignment_id = self.assignmentid
          aap.and_id = self.next_advanced_policy_and_id
          aap.or_id = self.next_advanced_policy_or_id
          aap.keyword = attempts
          aap.has = false
          aap.save
        end
        self.policy.reworkable = (attempts.to_i == 1 ? false : true)
        self.policy.save
        attempts
      end

      def next_advanced_policy_and_id
        self.advanced_policies.map{|p| p.and_id}.uniq.count
      end

      def next_advanced_policy_or_id(and_id=nil)
        return 0 if and_id.nil?
        self.advanced_policies.select{|p| p.and_id == and_id}.count
      end

      def remove_all_questions_and_groups
        self.assignment.remove_all_questions_and_groups
      end

      def question_groups
        self.assignment.question_groups
      end

      def clear_advanced_policies
        self.advanced_policies.each do |p|
          p.delete
        end
        self.reload
      end

      def add_advanced_policy(policy)
        aap = AssignmentAdvancedPolicy.new(
          :has => policy[:has],
          :keyword => policy[:keyword],
          :and_id => policy[:and_id],
          :or_id => policy[:or_id],
          :assignment_id => policy[:assignment_id]
        )
        aap.assignment_class_id = self.id
        aap.save!
      end

    end
  end
end