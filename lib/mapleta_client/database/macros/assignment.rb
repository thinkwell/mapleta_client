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
        AssignmentClass.with_pk!(assignment_class_id).copy({:class_id => new_class_id})
      end

      # Read advance policies to determine max attempts
      def assignment_max_attempts(assignment_class_id)
        AssignmentClass.with_pk!(assignment_class_id).max_attempts
      end

      def set_assignment_max_attempts(assignment_class_id, attempts)
        AssignmentClass.with_pk!(assignment_class_id).max_attempts = attempts
      end

      ##
      # Get or set assignment name for the given assignment_class_id
      def assignment_name(assignment_class_id, name=nil)

        assignment_class = AssignmentClass.with_pk!(assignment_class_id)

        unless name.nil?
          assignment_class.name = name
          assignment_class.assignment.name = name
          assignment_class.save
        end

        assignment_class.name

        #assignment_class = exec("SELECT assignmentid, name FROM assignment_class WHERE id=?", [assignment_class_id]).first
        #raise Errors::DatabaseError.new("Cannot find assignment_class with id=#{assignment_class_id}") unless assignment_class && assignment_class['assignmentid']
        #unless name === nil || name == assignment_class['name']
        #  exec("UPDATE assignment_class SET name=$1 WHERE id=?", [name, assignment_class_id])
        #  exec("UPDATE assignment SET name=? WHERE id=?", [name, assignment_class['assignmentid']])
        #end
        # Return old name
        #assignment_class['name']
      #rescue PG::Error => e
      #  raise Errors::DatabaseError.new(nil, e)
      end

    end
  end
end
