require 'uuid'

module Maple::MapleTA
  module Database::Macros
    module Assignment
      include Orm

      def copy_batch_assignments_to_class(new_class_id, recorded_assignment_ids, assignment_ids_and_names)
        raise Errors::DatabaseError.new("Must pass new_class_id") unless new_class_id

        assignment_class_id_old_to_new = {}

        assignment_classes_query_sql = "SELECT * FROM assignment_class WHERE id IN (#{recorded_assignment_ids.join(",")})"
        assignment_classes = exec(assignment_classes_query_sql)
        raise Errors::DatabaseError.new("Cannot find assignment_classes in recorded_assignment_ids=#{recorded_assignment_ids}") unless assignment_classes && assignment_classes.count > 0

        assignment_ids = assignment_classes.map{|a| a['assignmentid'].to_i}
        assignments_query_sql = "SELECT * FROM assignment WHERE id IN (#{assignment_ids.join(",")})"
        assignments = exec(assignments_query_sql)
        raise Errors::DatabaseError.new("Cannot find assignments in recorded_assignment_ids=#{recorded_assignment_ids}") unless assignments && assignments.count > 0

        assignment_class_ids = assignment_classes.map{|a| a['id'].to_i}
        assignment_policies_query_sql = "SELECT * FROM assignment_policy WHERE assignment_class_id IN (#{assignment_class_ids.join(",")})"
        assignment_policies = exec(assignment_policies_query_sql)

        assignment_question_groups_query_sql = "SELECT * FROM assignment_question_group WHERE assignmentid IN (#{assignment_ids.join(",")})"
        assignment_question_groups = exec(assignment_question_groups_query_sql)
        assignment_question_group_ids = assignment_question_groups.map{|a| a['id']}
        assignment_question_groups_query_sql = "SELECT * FROM assignment_question_group_map WHERE groupid IN (#{assignment_question_group_ids.join(",")})"
        assignment_question_group_maps = exec(assignment_question_groups_query_sql)
        new_group_ids = exec("SELECT nextval('assignment_question_group_id_seq') FROM generate_series(1, #{assignment_question_groups.count})")
        new_group_ids_index = 0

        assignment_mastery_policies_query_sql = "SELECT * FROM assignment_mastery_policy WHERE assignment_class_id IN (#{assignment_class_ids.join(",")})"
        assignment_mastery_policies = exec(assignment_mastery_policies_query_sql)

        assignment_mastery_penalties_query_sql = "SELECT * FROM assignment_mastery_penalty WHERE assignment_class_id IN (#{assignment_class_ids.join(",")})"
        assignment_mastery_penalties = exec(assignment_mastery_penalties_query_sql)

        assignment_advanced_policies_query_sql = "SELECT * FROM assignment_advanced_policy WHERE assignment_id IN (#{assignment_ids.join(",")})"
        assignment_advanced_policies = exec(assignment_advanced_policies_query_sql)

        new_assignment_ids = exec("SELECT nextval('assignment_id_seq') FROM generate_series(1, #{assignment_classes.count})")
        raise Errors::DatabaseError.new("Cannot determine new assignment ids") unless new_assignment_ids && new_assignment_ids.count > 0

        new_assignment_class_ids = exec("SELECT nextval('assignment_class_id_seq') FROM generate_series(1, #{assignment_classes.count})")
        raise Errors::DatabaseError.new("Cannot determine new assignment class ids") unless new_assignment_class_ids && new_assignment_class_ids.count > 0

        max_order_id = exec("SELECT MAX(order_id) FROM assignment_class WHERE classid=$1", [new_class_id]).first['max'].to_i

        transaction do
          assignment_insert_cmd = InsertCmd.new("assignment")
          assignment_class_insert_cmd = InsertCmd.new("assignment_class")
          assignment_policy_insert_cmd = InsertCmd.new("assignment_policy")
          assignment_question_group_insert_cmd = InsertCmd.new('assignment_question_group')
          assignment_question_group_map_insert_cmd = InsertCmd.new('assignment_question_group_map')
          assignment_mastery_policy_insert_cmd = InsertCmd.new("assignment_mastery_policy")
          assignment_mastery_penalty_insert_cmd = InsertCmd.new("assignment_mastery_penalty")
          assignment_advanced_policy_insert_cmd = InsertCmd.new("assignment_advanced_policy")

          assignment_classes.each_with_index do |assignment_class, index|
            new_assignment_id = new_assignment_ids.getvalue(index, 0)
            new_assignment_class_id = new_assignment_class_ids.getvalue(index, 0)
            name = assignment_ids_and_names[assignment_class['id'].to_i]
            unless name
              name = assignment_class['name']
            end
            assignment_class_id_old_to_new[assignment_class['id'].to_i] = new_assignment_class_id

            assignment = assignments.select{|a| a['id'] == assignment_class['assignmentid']}.first
            raise Errors::DatabaseError.new("Cannot find assignment with id=#{assignment_class['assignmentid']}") unless assignment
            push_assignment(assignment, new_assignment_id, new_class_id, {'name' => name}, assignment_insert_cmd)

            max_order_id = max_order_id + 1
            push_assignment_class(assignment_class, new_assignment_class_id, new_class_id, new_assignment_id, max_order_id, {'name' => name}, assignment_class_insert_cmd)

            assignment_policy = assignment_policies.select{|a| a['assignment_class_id'] == assignment_class['id']}.first
            push_assignment_policy(assignment_policy, new_assignment_class_id, assignment_policy_insert_cmd)

            assignment_question_groups_sub = assignment_question_groups.select{|a| a['assignmentid'] == assignment_class['assignmentid']}
            new_group_ids_sub = new_group_ids.to_a[new_group_ids_index..new_group_ids_index+assignment_question_groups_sub.count]
            push_assignment_question_groups(assignment_question_groups_sub, assignment_question_group_maps, new_group_ids_sub, new_assignment_id, assignment_question_group_insert_cmd, assignment_question_group_map_insert_cmd)
            new_group_ids_index = new_group_ids_index + assignment_question_groups_sub.count

            assignment_mastery_policies_sub = assignment_mastery_policies.select{|a| a['assignment_class_id'] == assignment_class['id']}
            push_assignment_mastery_policy(assignment_mastery_policies_sub, new_assignment_class_id, assignment_mastery_policy_insert_cmd)

            assignment_mastery_penalties_sub = assignment_mastery_penalties.select{|a| a['assignment_class_id'] == assignment_class['id']}
            push_assignment_mastery_penalty(assignment_mastery_penalties_sub, new_assignment_class_id, assignment_mastery_penalty_insert_cmd)

            assignment_advanced_policies_sub = assignment_advanced_policies.select{|a| a['assignment_id'] == assignment_class['assignmentid']}
            push_assignment_advanced_policy(assignment_advanced_policies_sub, new_assignment_id, new_assignment_class_id, assignment_advanced_policy_insert_cmd)
          end

          assignment_insert_cmd.execute
          assignment_class_insert_cmd.execute
          assignment_policy_insert_cmd.execute
          assignment_question_group_insert_cmd.execute
          assignment_question_group_map_insert_cmd.execute
          assignment_mastery_policy_insert_cmd.execute
          assignment_mastery_penalty_insert_cmd.execute
          assignment_advanced_policy_insert_cmd.execute
        end

        assignment_class_id_old_to_new
      rescue PG::Error => e
        Rails.logger.error e.backtrace.join("\n")
        raise Errors::DatabaseError.new(nil, e)
      end

      def save_assignment(assignment)
        assignment_class_attrs = {
          :classid     => assignment.classid,
          :name        => assignment.name,
          :totalpoints => assignment.total_points,
          :weighting   => assignment.weighting,
        }

        if assignment.assignment_class
          assignment_class_attrs[:id] = assignment.assignment_class.id
        end

        assignment.assignment_class_attributes = assignment_class_attrs

        assignment.assignment_class.assignment_policy_attributes = {
          :assignment_class_id       => assignment.assignment_class.try(:id),
          :show_current_grade        => assignment.show_current_grade,
          :insession_grade           => assignment.insession_grade,
          :reworkable                => assignment.reworkable,
          :printable                 => assignment.printable,
          :mode                      => assignment.mode || 0,
          :show_final_grade_feedback => assignment.show_final_grade_feedback
        }

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
        AssignmentClass.with_pk!(assignment_class_id).assignment.set(:class_id => new_class_id).deep_dup.save
        # ::::::::::Not specked::::::::::::::::::
        # assignment_policy = exec("SELECT * FROM assignment_policy WHERE assignment_class_id=?", assignment_class_id).first
        # raise Errors::DatabaseError.new("Cannot find assignment_policy with assignment_class_id=#{assignment_class_id}") unless assignment_policy
        # insert_assignment_policy(assignment_policy, new_assignment_class_id)

        # assignment_mastery_policies = exec("SELECT * FROM assignment_mastery_policy WHERE assignment_class_id=?", assignment_class_id)
        # insert_assignment_mastery_policy(assignment_mastery_policies, new_assignment_class_id)

        # assignment_mastery_penalties = exec("SELECT * FROM assignment_mastery_penalty WHERE assignment_class_id=?", assignment_class_id)
        # insert_assignment_mastery_penalty(assignment_mastery_penalties, new_assignment_class_id)

        # assignment_advanced_policy = exec("SELECT * FROM assignment_advanced_policy WHERE assignment_id=?", assignment_class['assignmentid'])
        # insert_assignment_advanced_policy(assignment_advanced_policy, new_assignment_id, new_assignment_class_id)
        # ::::::::::Not specked::::::::::::::::::
      end


      # Read advance policies to determine max attempts
      def assignment_max_attempts(assignment_class_id)
        raise Errors::DatabaseError.new("Must pass assignment_class_id") unless assignment_class_id
        assignment_class = exec("SELECT assignmentid, name FROM assignment_class WHERE id=$1", [assignment_class_id]).first
        raise Errors::DatabaseError.new("Cannot find assignment_class with id=#{assignment_class_id}") unless assignment_class && assignment_class['assignmentid']

        results = exec("SELECT * FROM assignment_advanced_policy WHERE assignment_class_id=$1 AND assignment_id=$2 AND has='f'", [assignment_class_id, assignment_class['assignmentid']]).first
        return results['keyword'].to_i if results && results['keyword'] && results['keyword'].to_i > 0
        false
      end

      def set_assignment_max_attempts(assignment_class_id, max_attempts)
        raise Errors::DatabaseError.new("Must pass assignment_class_id") unless assignment_class_id
        assignment_class = exec("SELECT assignmentid, name FROM assignment_class WHERE id=?", assignment_class_id).first


        raise Errors::DatabaseError.new("Cannot find assignment_class with id=#{assignment_class_id}") unless assignment_class && assignment_class[:assignmentid]

        unless max_attempts
          exec("DELETE FROM assignment_advanced_policy WHERE assignment_class_id=$1 AND assignment_id=$2 AND has='f'", [assignment_class_id, assignment_class['assignmentid']])
        else
          existing = exec("SELECT * FROM assignment_advanced_policy WHERE assignment_class_id=$1 AND assignment_id=$2 AND has='f'", [assignment_class_id, assignment_class['assignmentid']]).first
          if existing
            exec("UPDATE assignment_advanced_policy SET keyword=$3 WHERE assignment_class_id=$1 AND assignment_id=$2 AND has='f'", [assignment_class_id, assignment_class['assignmentid'], max_attempts])
          else
            exec("INSERT INTO assignment_advanced_policy (assignment_class_id, and_id, or_id, keyword, assignment_id, has) VALUES ($1, 0, 0, $3, $2, 'f')", [assignment_class_id, assignment_class['assignmentid'], max_attempts])
          end
        end

      end
    end
  end
end

class Cmd
  attr_reader :table_name, :values, :condition

  def initialize(table_name, condition = nil)
    @table_name = table_name.to_sym
    @condition  = condition
  end

  def push(hash, except = [], override = {}, additional_columns = {})
    new_hash = hash.to_hash.stringify_keys
    new_hash = new_hash.delete_if { |key, val| except.include? key.to_s }
    override = override.delete_if { |key, value| not new_hash.keys.include?(key.to_s) }

    new_hash.merge! override
    new_hash.merge! additional_columns

    @values = new_hash
  end

  def dataset
    dataset = Maple::MapleTA.database_connection.dataset[table_name]
    @condition ? dataset.where(@condition) : dataset
  end
end


class InsertCmd < Cmd
  def execute
    dataset.insert(values) if values
  end
end


class UpdateCmd < Cmd
  def execute
    dataset.update(values) if values
  end
end
