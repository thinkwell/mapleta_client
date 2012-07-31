require 'uuid'

module Maple::MapleTA
  module Database::Macros
    module Assignment

      def copy_assignment_to_class(assignment_class_id, new_class_id)
        raise Errors::DatabaseError.new("Must pass assignment_class_id") unless assignment_class_id
        raise Errors::DatabaseError.new("Must pass new_class_id") unless new_class_id

        assignment_class = exec("SELECT * FROM assignment_class WHERE id=$1", [assignment_class_id]).first
        raise Errors::DatabaseError.new("Cannot find assignment_class with id=#{assignment_class_id}") unless assignment_class && assignment_class['assignmentid']

        assignment = exec("SELECT * FROM assignment WHERE id=$1", [assignment_class['assignmentid']]).first
        raise Errors::DatabaseError.new("Cannot find assignment with id=#{assignment_class['assignmentid']}") unless assignment

        new_assignment_class_id = nil
        transaction do
          # Create new assignment
          new_assignment_uid = "#{::UUID.new.generate.to_s}-#{new_class_id}"
          cols = sql_cols_for(assignment, %w(id lastmodified), {'classid' => new_class_id, 'uid' => new_assignment_uid})
          exec("INSERT INTO assignment (#{cols[:keys]}, lastmodified) VALUES (#{cols[:vals]}, NOW())", cols[:params])
          new_assignment_id = exec("SELECT currval('assignment_id_seq')").first['currval'].to_i
          raise Errors::DatabaseError.new("Cannot determine new assignment id") unless new_assignment_id && new_assignment_id > 0

          # Create new assignment_class
          new_order_id = exec("SELECT MAX(order_id) FROM assignment_class WHERE classid=$1", [new_class_id]).first['max'].to_i + 1
          cols = sql_cols_for(assignment_class, %w(id lastmodified parent), {'classid' => new_class_id, 'assignmentid' => new_assignment_id, 'order_id' => new_order_id})
          exec("INSERT INTO assignment_class (#{cols[:keys]}, lastmodified) VALUES (#{cols[:vals]}, NOW())", cols[:params])
          new_assignment_class_id = exec("SELECT currval('assignment_class_id_seq')").first['currval'].to_i
          raise Errors::DatabaseError.new("Cannot determine new assignment_class id") unless new_assignment_class_id && new_assignment_class_id > 0

          # Copy assignment_policy
          assignment_policy = exec("SELECT * FROM assignment_policy WHERE assignment_class_id=$1", [assignment_class_id]).first
          raise Errors::DatabaseError.new("Cannot find assignment_policy with assignment_class_id=#{assignment_class_id}") unless assignment_policy
          cols = sql_cols_for(assignment_policy, %w(), {'assignment_class_id' => new_assignment_class_id})
          exec("INSERT INTO assignment_policy (#{cols[:keys]}) VALUES (#{cols[:vals]})", cols[:params])

          # We ignore advance policies as they depend on other assignments in the original class

          # Copy assignment_question_group and assignment_question_group_map
          assignment_question_groups = exec("SELECT * FROM assignment_question_group WHERE assignmentid=$1", [assignment_class['assignmentid']])
          assignment_question_groups.each do |assignment_question_group|
            cols = sql_cols_for(assignment_question_group, %w(id), {'assignmentid' => new_assignment_id})
            exec("INSERT INTO assignment_question_group (#{cols[:keys]}) VALUES (#{cols[:vals]})", cols[:params])
            new_group_id = exec("SELECT currval('assignment_question_group_id_seq')").first['currval'].to_i
            raise Errors::DatabaseError.new("Cannot determine new assignment_question_group id") unless new_group_id && new_group_id > 0

            assignment_question_group_maps = exec("SELECT * FROM assignment_question_group_map WHERE groupid=$1", [assignment_question_group['id']])
            assignment_question_group_maps.each do |assignment_question_group_map|
              cols = sql_cols_for(assignment_question_group_map, %w(id), {'groupid' => new_group_id})
              exec("INSERT INTO assignment_question_group_map (#{cols[:keys]}) VALUES (#{cols[:vals]})", cols[:params])
              new_group_map_id = exec("SELECT currval('assignment_question_group_map_id_seq')").first['currval'].to_i
              raise Errors::DatabaseError.new("Cannot determine new assignment_question_group_map id") unless new_group_map_id && new_group_map_id > 0
            end
          end

          # Copy assignment_mastery_policy
          assignment_mastery_policies = exec("SELECT * FROM assignment_mastery_policy WHERE assignment_class_id=$1", [assignment_class_id])
          assignment_mastery_policies.each do |assignment_mastery_policy|
            cols = sql_cols_for(assignment_mastery_policy, %w(), {'assignment_class_id' => new_assignment_class_id})
            exec("INSERT INTO assignment_mastery_policy (#{cols[:keys]}) VALUES (#{cols[:vals]})", cols[:params])
          end

          # Copy assignment_mastery_penalty
          assignment_mastery_penalties = exec("SELECT * FROM assignment_mastery_penalty WHERE assignment_class_id=$1", [assignment_class_id])
          assignment_mastery_penalties.each do |assignment_mastery_penalty|
            cols = sql_cols_for(assignment_mastery_penalty, %w(), {'assignment_class_id' => new_assignment_class_id})
            exec("INSERT INTO assignment_mastery_penalty (#{cols[:keys]}) VALUES (#{cols[:vals]})", cols[:params])
          end
        end

        new_assignment_class_id
      rescue PG::Error => e
        raise Errors::DatabaseError.new(nil, e)
      end

      ##
      # Get or set assignment name for the given assignment_class_id
      def assignment_name(assignment_class_id, name=nil)
        assignment_class = exec("SELECT assignmentid, name FROM assignment_class WHERE id=$1", [assignment_class_id]).first
        raise Errors::DatabaseError.new("Cannot find assignment_class with id=#{assignment_class_id}") unless assignment_class && assignment_class['assignmentid']
        unless name === nil || name == assignment_class['name']
          exec("UPDATE assignment_class SET name=$1 WHERE id=$2", [name, assignment_class_id])
          exec("UPDATE assignment SET name=$1 WHERE id=$2", [name, assignment_class['assignmentid']])
        end
        # Return old name
        assignment_class['name']
      rescue PG::Error => e
        raise Errors::DatabaseError.new(nil, e)
      end
    end
  end
end
