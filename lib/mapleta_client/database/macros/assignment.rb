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

      def create_assignment(assignment)
        transaction do
          assignment.assignment_class_attributes =
            assignment.assignment_class_hash

          assignment.assignment_class.assignment_policy_attributes =
            assignment.assignment_policy_hash

          assignment.save

          # assignment.assignment_class.assignment_policy = AssignmentPolicy.new

          insert_assignment_question_groups(
            assignment.assignment_question_group_hashes,
            assignment.assignment_question_group_map_hashes,
            assignment.id
          )

          # ::::::::::Not specked::::::::::::::::::
          # insert_assignment_mastery_policy(
          #   assignment.assignment_mastery_policy_hashes,
          #   assignment_class.id
          # )
          # insert_assignment_mastery_penalty(
          #   assignment.assignment_mastery_penalty_hashes,
          #   assignment_class.id
          # )
          # insert_assignment_advanced_policy(
          #   assignment.assignment_advanced_policy_hashes,
          #   assignment.id,
          #   assignment_class.id
          # )
          # ::::::::::Not specked::::::::::::::::::

          return assignment.id
        end
      end

      def edit_assignment(assignment)
        transaction do
          update_assignment(assignment)

          update_assignment_class(assignment)

          update_assignment_policy(assignment)

          update_assignment_question_groups(assignment)
          #
          #insert_assignment_mastery_policy(assignment.assignment_mastery_policy_hashes, new_assignment_class_id)
          #
          #insert_assignment_mastery_penalty(assignment.assignment_mastery_penalty_hashes, new_assignment_class_id)
          #
          #insert_assignment_advanced_policy(assignment.assignment_advanced_policy_hashes, new_assignment_id, new_assignment_class_id)
          #
        end
      end

      def copy_assignment_to_class(assignment_class_id, new_class_id)
        assignment_class = AssignmentClass.with_pk!(assignment_class_id)
        assignment = assignment_class.assignment

        transaction do
          new_assignment_id       = insert_assignment(assignment, new_class_id)
          new_assignment_class_id = insert_assignment_class(assignment_class, new_class_id, new_assignment_id)


          # ::::::::::Not specked::::::::::::::::::
          assignment_policy = exec("SELECT * FROM assignment_policy WHERE assignment_class_id=?", assignment_class_id).first
          raise Errors::DatabaseError.new("Cannot find assignment_policy with assignment_class_id=#{assignment_class_id}") unless assignment_policy
          insert_assignment_policy(assignment_policy, new_assignment_class_id)

          # We ignore advance policies as they depend on other assignments in the original class
          assignment_question_groups     = assignment_question_groups assignment_class.assignmentid
          assignment_question_group_maps = assignment_question_group_maps assignment_class.assignmentid
          insert_assignment_question_groups(assignment_question_groups, assignment_question_group_maps, new_assignment_id)

          assignment_mastery_policies = exec("SELECT * FROM assignment_mastery_policy WHERE assignment_class_id=?", assignment_class_id)
          insert_assignment_mastery_policy(assignment_mastery_policies, new_assignment_class_id)

          assignment_mastery_penalties = exec("SELECT * FROM assignment_mastery_penalty WHERE assignment_class_id=?", assignment_class_id)
          insert_assignment_mastery_penalty(assignment_mastery_penalties, new_assignment_class_id)

          assignment_advanced_policy = exec("SELECT * FROM assignment_advanced_policy WHERE assignment_id=?", assignment_class['assignmentid'])
          insert_assignment_advanced_policy(assignment_advanced_policy, new_assignment_id, new_assignment_class_id)
          # ::::::::::Not specked::::::::::::::::::

          return new_assignment_class_id
        end
      end

      def insert_assignment_mastery_penalty(assignment_mastery_penalty_hashes, new_assignment_class_id)
        assignment_mastery_penalty_insert_cmd = InsertCmd.new("assignment_mastery_penalty")
        push_assignment_mastery_penalty(assignment_mastery_penalty_hashes, new_assignment_class_id, assignment_mastery_penalty_insert_cmd)
        assignment_mastery_penalty_insert_cmd.execute
      end

      def push_assignment_mastery_penalty(assignment_mastery_penalties, new_assignment_class_id, assignment_mastery_penalty_insert_cmd)
        assignment_mastery_penalties.each do |assignment_mastery_penalty|
          assignment_mastery_penalty_insert_cmd.push(assignment_mastery_penalty, [], {'assignment_class_id' => new_assignment_class_id})
        end
      end

      def insert_assignment_advanced_policy(assignment_advanced_policy_hashes, new_assignment_id, new_assignment_class_id)
        assignment_advanced_policy_insert_cmd = InsertCmd.new("assignment_advanced_policy")
        push_assignment_advanced_policy(assignment_advanced_policy_hashes, new_assignment_id, new_assignment_class_id, assignment_advanced_policy_insert_cmd)
        assignment_advanced_policy_insert_cmd.execute
      end

      def push_assignment_advanced_policy(assignment_advanced_policies, new_assignment_id, new_assignment_class_id, assignment_advanced_policy_insert_cmd)
        assignment_advanced_policies.each do |assignment_advanced_policy|
          assignment_advanced_policy_insert_cmd.push(assignment_advanced_policy, [], {'assignment_class_id' => new_assignment_class_id, 'assignment_id' => new_assignment_id})
        end
      end

      def insert_assignment_mastery_policy(assignment_mastery_policy_hashes, new_assignment_class_id)
        assignment_mastery_policy_insert_cmd = InsertCmd.new("assignment_mastery_policy")
        push_assignment_mastery_policy(assignment_mastery_policy_hashes, new_assignment_class_id, assignment_mastery_policy_insert_cmd)
        assignment_mastery_policy_insert_cmd.execute
      end

      def push_assignment_mastery_policy(assignment_mastery_policies, new_assignment_class_id, assignment_mastery_policy_insert_cmd)
        assignment_mastery_policies.each do |assignment_mastery_policy|
          assignment_mastery_policy_insert_cmd.push(assignment_mastery_policy, [], {'assignment_class_id' => new_assignment_class_id})
        end
      end

      def insert_assignment(assignment_hash, new_class_id)
        cmd = InsertCmd.new("assignment")
        id  = exec("SELECT nextval('assignment_id_seq')").first['nextval']

        push_assignment assignment_hash, id, new_class_id, {}, cmd
        cmd.execute
      end

      def update_assignment(assignment)
        assignment_hash = assignment.to_hash
        assignment_update_cmd = UpdateCmd.new("assignment", "id=#{assignment.id}")
        push_assignment(assignment_hash, assignment.id, assignment.class_id, {}, assignment_update_cmd)
        assignment_update_cmd.execute
      end

      def push_assignment(assignment, new_assignment_id, new_class_id, overrides, assignment_insert_cmd)
        new_assignment_uid = "#{::UUID.new.generate.to_s}-#{new_class_id}"

        assignment_insert_cmd.push(
          assignment,
          %w(lastmodified),
          {'id' => new_assignment_id, 'classid' => new_class_id, 'uid' => new_assignment_uid}.merge(overrides),
          {'lastmodified' => 'NOW()'}
        )
      end

      def insert_assignment_class(hash, class_id, assignment_id)
        cmd = InsertCmd.new("assignment_class")
        id  = exec("SELECT nextval('assignment_class_id_seq')").first['nextval']
        order_id = exec("SELECT MAX(order_id) FROM assignment_class WHERE classid=?", class_id).first['max'].to_i + 1

        push_assignment_class hash, id, class_id, assignment_id, order_id, {}, cmd
        cmd.execute
      end

      def update_assignment_class(assignment)
        assignment_class = assignment_class_for_assignmentid assignment.id
        cmd = UpdateCmd.new("assignment_class", "id=#{assignment_class.id}")

        push_assignment_class(
          assignment.assignment_class_hash,
          assignment_class['id'],
          assignment.class_id, assignment.id,
          assignment_class['order_id'],
          {},
          cmd
        )

        cmd.execute
      end

      def push_assignment_class(assignment_class, new_assignment_class_id, new_class_id, new_assignment_id, new_order_id, overrides, assignment_class_insert_cmd)
        assignment_class_insert_cmd.push(assignment_class, %w(lastmodified parent), {'id' => new_assignment_class_id, 'classid' => new_class_id, 'assignmentid' => new_assignment_id, 'order_id' => new_order_id}.merge(overrides), {'lastmodified' => 'NOW()'})
      end

      def insert_assignment_policy(hash, assignment_class_id)
        cmd = InsertCmd.new("assignment_policy")
        push_assignment_policy hash, assignment_class_id, cmd
        cmd.execute
      end

      def update_assignment_policy(assignment)
        assignment_policy = assignment_policy_for_assignmentid assignment.id
        cmd = UpdateCmd.new("assignment_policy", "assignment_class_id=#{assignment_policy['assignment_class_id']}")

        push_assignment_policy(
          assignment.assignment_policy_hash,
          assignment_policy['assignment_class_id'],
          cmd
        )

        cmd.execute
      end

      def push_assignment_policy(assignment_policy, new_assignment_class_id, assignment_policy_insert_cmd)
        assignment_policy_insert_cmd.push(assignment_policy, [], {'assignment_class_id' => new_assignment_class_id})
      end

      def insert_assignment_question_groups(assignment_question_group_hashes, assignment_question_group_map_hashes, new_assignment_id)
        assignment_question_group_insert_cmd     = InsertCmd.new('assignment_question_group')
        assignment_question_group_map_insert_cmd = InsertCmd.new('assignment_question_group_map')

        new_group_ids = exec("SELECT nextval('assignment_question_group_id_seq') FROM generate_series(1, #{assignment_question_group_hashes.count})")

        push_assignment_question_groups(
          assignment_question_group_hashes,
          assignment_question_group_map_hashes,
          new_group_ids,
          new_assignment_id,
          assignment_question_group_insert_cmd,
          assignment_question_group_map_insert_cmd
        )

        assignment_question_group_insert_cmd.execute
        assignment_question_group_map_insert_cmd.execute
      end

      def update_assignment_question_groups(assignment)
        assignment_question_groups     = assignment_question_groups assignment.id
        assignment_question_group_maps = assignment_question_group_maps assignment.id

        assignment_question_group_maps_to_delete =
          assignment_question_group_maps.select { |map| !assignment.include_questionid?(map['questionid']) }

        assignment_question_group_maps_to_delete.each{ |map| delete_assignment_question_group(map) }

        questionids         = assignment_question_group_maps.map{ |a| a['questionid'] }
        questions_to_insert = assignment.questions.select { |question| !questionids.include?(question['id']) }

        insert_assignment_question_groups(
          assignment.assignment_question_group_hashes(questions_to_insert),
          assignment.assignment_question_group_map_hashes(questions_to_insert),
          assignment.id
        )
      end

      # Copy assignment_question_group and assignment_question_group_map
      def push_assignment_question_groups(
        assignment_question_group_hashes,
        assignment_question_group_maps_all_hashes,
        new_group_ids,
        new_assignment_id,
        assignment_question_group_insert_cmd,
        assignment_question_group_map_insert_cmd
      )


        assignment_question_group_hashes.each_with_index do |assignment_question_group_hash, index|
          new_group_id = new_group_ids[index]['nextval']

          raise Errors::DatabaseError.new("Cannot determine new assignment_question_group id") unless new_group_id && new_group_id > 0

          assignment_question_group_insert_cmd.push(assignment_question_group_hash, [], {'id' => new_group_id, 'assignmentid' => new_assignment_id})

          assignment_question_group_map_hashes = assignment_question_group_maps_all_hashes.select{ |a|  a['groupid'] == assignment_question_group_hash['id'] }

          assignment_question_group_map_hashes.each do |assignment_question_group_map_hash|
            assignment_question_group_map_insert_cmd.push(assignment_question_group_map_hash, %w(id), {'groupid' => new_group_id})
          end
        end
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

      ##
      # Get assignment ids and names for the given class_id
      def assignment_ids_and_names(assignment_class_id)
        results = exec("SELECT id, name FROM assignment_class WHERE classid=$1", [assignment_class_id]).to_a
        results
      rescue PG::Error => e
        raise Errors::DatabaseError.new(nil, e)
      end

      ##
      # Get the assignment policy database row for a given assignment_class_id
      def assignment_policy(assignment_class_id)
        raise Errors::DatabaseError.new("Must pass assignment_class_id") unless assignment_class_id
        exec("SELECT * FROM assignment_policy WHERE assignment_class_id=?", assignment_class_id).first
      end

      ##
      # Get the assignment policy database row for a given assignmentid
      def assignment_policy_for_assignmentid(assignmentid)
        raise Errors::DatabaseError.new("Must pass assignmentid") unless assignmentid
        exec("SELECT p.* FROM assignment_policy p left join assignment_class a on a.id = p.assignment_class_id WHERE a.assignmentid=?", assignmentid).first
      end

      ##
      # Get the assignment question group database row for a given assignmentid
      def assignment_question_groups(assignment_id)
        Orm::Assignment.with_pk!(assignment_id).assignment_question_groups
      end

      ##
      # Get the assignment question group database row for a given assignmentid
      def assignment_question_group_maps(assignmentid)
        raise Errors::DatabaseError.new("Must pass assignmentid") unless assignmentid
        exec("SELECT m.* FROM assignment_question_group_map m left join assignment_question_group a on a.id = m.groupid WHERE a.assignmentid=?", assignmentid)
      end

      ##
      # Get the assignment database row for a given classid
      def assignment(classid)
        Orm::Assignment.where(classid: classid).first!
      end

      ##
      # Get the assignment_class database row for a given classid
      def assignment_class(classid)
        AssignmentClass.where(classid: classid).first!
      end

      ##
      # Get the assignment_class database row for a given assignmentid
      def assignment_class_for_assignmentid(assignmentid)
        AssignmentClass.where(assignmentid: assignmentid).first!
      end

      ##
      # Delete the assignment database row for a given classid
      def delete_assignment(classid)
        raise Errors::DatabaseError.new("Must pass classid") unless classid
        assignment = assignment(classid)
        return unless assignment
        assignment_question_group_maps(assignment['id']).each do |assignment_question_group_map|
          delete_assignment_question_group(assignment_question_group_map)
        end
        exec("DELETE FROM assignment WHERE classid=$1", [classid]).first
      end

      def delete_assignment_question_group(assignment_question_group_map)
        exec "DELETE FROM assignment_question_group_map WHERE id=?", assignment_question_group_map['id']
        exec "DELETE FROM assignment_question_group WHERE id=?", assignment_question_group_map['groupid']
      end

      ##
      # Delete the assignment_class database row for a given classid
      def delete_assignment_class(classid)
        raise Errors::DatabaseError.new("Must pass classid") unless classid
        assignment_class = assignment_class(classid)
        return unless assignment_class
        exec("DELETE FROM assignment_policy WHERE assignment_class_id=$1", [assignment_class['id']]).first
        exec("DELETE FROM assignment_class WHERE classid=$1", [classid]).first
      end

      ##
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
