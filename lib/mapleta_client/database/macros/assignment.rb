require 'uuid'

module Maple::MapleTA
  module Database::Macros
    module Assignment
      include Orm

      def save_assignment(assignment)
        assignment_class_attrs = {
          :classid     => assignment.classid,
          :name        => assignment.name,
          :totalpoints => assignment.total_points,
          :weighting   => assignment.weighting,
          :assignment_policy_attributes => {
            :assignment_class_id       => assignment.assignment_classes.first.try(:id),
            :show_current_grade        => assignment.show_current_grade,
            :insession_grade           => assignment.insession_grade,
            :reworkable                => assignment.reworkable,
            :printable                 => assignment.printable,
            :mode                      => assignment.mode || 0,
            :show_final_grade_feedback => assignment.show_final_grade_feedback
          }
        }

        if assignment.assignment_classes.size > 0
          assignment_class_attrs[:id] = assignment.assignment_classes.first.id
        end

        assignment.assignment_classes_attributes = [assignment_class_attrs]

        question_group_attrs = []

        unless assignment.new?
          question_ids = assignment.questions.map(&:id)
          group_ids    = assignment.assignment_question_group_maps_dataset.select_hash(:questionid, :groupid)
          deletable_question_ids = group_ids.keys - question_ids
          question_group_attrs   = deletable_question_ids.map { |qid| { :id => group_ids[qid], :_delete => true } }
        end

        question_group_attrs += assignment.questions.map do |question|
          attrs = {
            :name => question.name, :order_id => 0,
            :assignment_question_group_maps_attributes => [ {:question_id => question.id, :question_uid => question.uid} ]
          }
          attrs[:id] = id if id = group_ids[question.id] unless assignment.new?
          attrs
        end

        assignment.assignment_question_groups_attributes = question_group_attrs
        assignment.save.reload
      end

      alias create_assignment save_assignment
      alias edit_assignment save_assignment

      def copy_assignment_to_class(assignment_class_id, new_class_id)
        transaction do
          assignment_class = AssignmentClass.with_pk!(assignment_class_id)
          new_assignment_class =
            assignment_class.set(:class_id => new_class_id).
            deep_dup :assignment_policy, :assignment => {
              :assignment_question_groups => :assignment_question_group_maps
            }

          new_assignment_class.assignment.class_id = new_class_id

          new_assignment_class.save

          if adv_policy = assignment_class.advanced_policy
            new_adv_policy_attrs = adv_policy.to_hash.merge(:assignment_class_id => new_assignment_class.id)
            new_assignment_class.advanced_policy = AdvancedPolicy.new(new_adv_policy_attrs).save
          end

          new_assignment_class
        end
      end

      # Read advance policies to determine max attempts
      def assignment_max_attempts(assignment_class_id)
        assignment_class = AssignmentClass.with_pk!(assignment_class_id)
        assignment_class.advanced_policy.try(:keyword) or false
      end

      def set_assignment_max_attempts(assignment_class_id, max_attempts)
        assignment_class = AssignmentClass.with_pk!(assignment_class_id)

        if max_attempts.present?
          assignment_class.advanced_policy_attributes = {
            :assignment_class_id => assignment_class.id,
            :assignment_id       => assignment_class.assignment_id,
            :keyword             => max_attempts,
            :and_id              => 0,
            :or_id               => 0,
            :has                 => false,
          }

          assignment_class.save
        else
          assignment_class.advanced_policy_dataset.destroy
        end
      end
    end
  end
end
