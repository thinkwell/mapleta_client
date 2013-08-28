require 'uuid'

module Maple::MapleTA
  module Database::Macros
    module Assignment

      def execute(cmd)
        return if cmd.empty?
        #Rails.logger.debug "insert sql : #{cmd.sql}, insert values #{cmd.values.join(",")}"
        exec(cmd.sql, cmd.values)
      end

      def copy_batch_assignments_to_class(new_class_id, recorded_assignment_ids, assignment_ids_and_names)
        raise Errors::DatabaseError.new("Must pass new_class_id") unless new_class_id

        assignment_class_id_old_to_new = {}
        t1 = Time.now
        assignment_classes_query_sql = "SELECT * FROM assignment_class WHERE id IN (#{recorded_assignment_ids.join(",")})"
        assignment_classes = exec(assignment_classes_query_sql)
        raise Errors::DatabaseError.new("Cannot find assignment_classes in recorded_assignment_ids=#{recorded_assignment_ids}") unless assignment_classes && assignment_classes.count > 0
        #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#select_assignment_classes #{assignment_classes.count} in #{time_diff t1, Time.now}"

        t11 = Time.now
        assignment_ids = assignment_classes.map{|a| a['assignmentid'].to_i}
        assignments_query_sql = "SELECT * FROM assignment WHERE id IN (#{assignment_ids.join(",")})"
        assignments = exec(assignments_query_sql)
        raise Errors::DatabaseError.new("Cannot find assignments in recorded_assignment_ids=#{recorded_assignment_ids}") unless assignments && assignments.count > 0
        #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#select_assignments #{assignments.count} in #{time_diff t11, Time.now}"

        t12 = Time.now
        assignment_class_ids = assignment_classes.map{|a| a['id'].to_i}
        assignment_policies_query_sql = "SELECT * FROM assignment_policy WHERE assignment_class_id IN (#{assignment_class_ids.join(",")})"
        assignment_policies = exec(assignment_policies_query_sql)
        #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#select_assignment_policies #{assignment_policies.count} in #{time_diff t12, Time.now}"

        t13 = Time.now
        assignment_question_groups_query_sql = "SELECT * FROM assignment_question_group WHERE assignmentid IN (#{assignment_ids.join(",")})"
        assignment_question_groups = exec(assignment_question_groups_query_sql)
        assignment_question_group_ids = assignment_question_groups.map{|a| a['id']}
        assignment_question_groups_query_sql = "SELECT * FROM assignment_question_group_map WHERE groupid IN (#{assignment_question_group_ids.join(",")})"
        assignment_question_group_maps = exec(assignment_question_groups_query_sql)
        new_group_ids = exec("SELECT nextval('assignment_question_group_id_seq') FROM generate_series(1, #{assignment_question_groups.count})")
        new_group_ids_index = 0
        #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#select_assignment_question_groups #{assignment_question_groups.count}/#{assignment_question_group_maps.count} in #{time_diff t13, Time.now}"

        t14 = Time.now
        assignment_mastery_policies_query_sql = "SELECT * FROM assignment_mastery_policy WHERE assignment_class_id IN (#{assignment_class_ids.join(",")})"
        assignment_mastery_policies = exec(assignment_mastery_policies_query_sql)
        #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#select_assignment_mastery_policies #{assignment_mastery_policies.count} in #{time_diff t14, Time.now}"

        t15 = Time.now
        assignment_mastery_penalties_query_sql = "SELECT * FROM assignment_mastery_penalty WHERE assignment_class_id IN (#{assignment_class_ids.join(",")})"
        assignment_mastery_penalties = exec(assignment_mastery_penalties_query_sql)
        #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#select_assignment_mastery_penalties #{assignment_mastery_penalties.count} in #{time_diff t15, Time.now}"

        t16 = Time.now
        assignment_advanced_policies_query_sql = "SELECT * FROM assignment_advanced_policy WHERE assignment_id IN (#{assignment_ids.join(",")})"
        assignment_advanced_policies = exec(assignment_advanced_policies_query_sql)
        #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#select_assignment_mastery_penalties #{assignment_mastery_penalties.count} in #{time_diff t15, Time.now}"

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
              #puts "No name found for assignment class id #{assignment_class['id'].to_i} - using #{name}"
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

          t7 = Time.now
          execute(assignment_insert_cmd)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#insert_assignments in #{time_diff t7, Time.now}"
          t71 = Time.now
          execute(assignment_class_insert_cmd)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#insert_assignment_classes in #{time_diff t71, Time.now}"
          t72 = Time.now
          execute(assignment_policy_insert_cmd)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#insert_assignment_policies in #{time_diff t72, Time.now}"
          t73 = Time.now
          execute(assignment_question_group_insert_cmd)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#insert_assignment_question_groups in #{time_diff t73, Time.now}"
          t74 = Time.now
          execute(assignment_question_group_map_insert_cmd)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#insert_assignment_question_group_maps in #{time_diff t74, Time.now}"
          t75 = Time.now
          execute(assignment_mastery_policy_insert_cmd)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#insert_assignment_mastery_policies in #{time_diff t75, Time.now}"
          t76 = Time.now
          execute(assignment_mastery_penalty_insert_cmd)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#insert_assignment_mastery_penalties in #{time_diff t76, Time.now}"
          t77 = Time.now
          execute(assignment_advanced_policy_insert_cmd)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_batch_assignments_to_class#assignment_advanced_policy_insert_cmd in #{time_diff t77, Time.now}"
        end
        assignment_class_id_old_to_new
      rescue PG::Error => e
        Rails.logger.error e.backtrace.join("\n")
        raise Errors::DatabaseError.new(nil, e)
      end

      def create_assignment(assignment)
        new_assignment_id, new_assignment_class_id = nil
        transaction do
          new_assignment_id = insert_assignment(assignment.assignment_hash, assignment.class_id)

          new_assignment_class_id = insert_assignment_class(assignment.assignment_class_hash, assignment.class_id, new_assignment_id)

          insert_assignment_policy(assignment.assignment_policy_hash, new_assignment_class_id)

          insert_assignment_question_groups(assignment.assignment_question_groups, new_assignment_id)

          insert_assignment_mastery_policy(assignment.assignment_mastery_policy_hashes, new_assignment_class_id)

          insert_assignment_mastery_penalty(assignment.assignment_mastery_penalty_hashes, new_assignment_class_id)

          insert_assignment_advanced_policy(assignment.assignment_advanced_policy_hashes, new_assignment_id, new_assignment_class_id)

        end
        [new_assignment_id, new_assignment_class_id]
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
        raise Errors::DatabaseError.new("Must pass assignment_class_id") unless assignment_class_id
        raise Errors::DatabaseError.new("Must pass new_class_id") unless new_class_id

        t1 = Time.now
        assignment_class = exec("SELECT * FROM assignment_class WHERE id=$1", [assignment_class_id]).first
        raise Errors::DatabaseError.new("Cannot find assignment_class with id=#{assignment_class_id}") unless assignment_class && assignment_class['assignmentid']

        assignment = exec("SELECT * FROM assignment WHERE id=$1", [assignment_class['assignmentid']]).first
        raise Errors::DatabaseError.new("Cannot find assignment with id=#{assignment_class['assignmentid']}") unless assignment
        #puts "Maple::MapleTA::Database::Macros::Assignment copy_assignment_to_class#select in #{time_diff t1, Time.now}"

        new_assignment_class_id = nil
        transaction do
          t2 = Time.now
          new_assignment_id = insert_assignment(assignment, new_class_id)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_assignment_to_class#insert_assignment in #{time_diff t2, Time.now}"

          t3 = Time.now
          new_assignment_class_id = insert_assignment_class(assignment_class, new_class_id, new_assignment_id)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_assignment_to_class#insert_assignment_class in #{time_diff t3, Time.now}"

          t4 = Time.now
          assignment_policy = exec("SELECT * FROM assignment_policy WHERE assignment_class_id=$1", [assignment_class_id]).first
          raise Errors::DatabaseError.new("Cannot find assignment_policy with assignment_class_id=#{assignment_class_id}") unless assignment_policy
          insert_assignment_policy(assignment_policy, new_assignment_class_id)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_assignment_to_class#insert_assignment_policy in #{time_diff t4, Time.now}"

          # We ignore advance policies as they depend on other assignments in the original class
          t5 = Time.now
          assignment_question_groups = assignment_question_groups(assignment_class['assignmentid'])
          assignment_question_group_maps = assignment_question_group_maps(assignment_class['assignmentid'])
          assignment_question_groups.each do |assignment_question_group|
            assignment_question_group.assignment_question_group_maps = assignment_question_group_maps.select{|map| map.groupid == assignment_question_group.id}
          end
          insert_assignment_question_groups(assignment_question_groups, new_assignment_id)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_assignment_to_class#insert_assignment_question_groups in #{time_diff t5, Time.now}"

          t6 = Time.now
          assignment_mastery_policies = exec("SELECT * FROM assignment_mastery_policy WHERE assignment_class_id=$1", [assignment_class_id])
          insert_assignment_mastery_policy(assignment_mastery_policies, new_assignment_class_id)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_assignment_to_class#insert_assignment_mastery_policy in #{time_diff t6, Time.now}"

          t7 = Time.now
          assignment_mastery_penalties = exec("SELECT * FROM assignment_mastery_penalty WHERE assignment_class_id=$1", [assignment_class_id])
          insert_assignment_mastery_penalty(assignment_mastery_penalties, new_assignment_class_id)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_assignment_to_class#insert_assignment_mastery_penalty in #{time_diff t7, Time.now}"

          t8 = Time.now
          assignment_advanced_policy = exec("SELECT * FROM assignment_advanced_policy WHERE assignment_id=$1", [assignment_class['assignmentid']])
          insert_assignment_advanced_policy(assignment_advanced_policy, new_assignment_id, new_assignment_class_id)
          #puts "Maple::MapleTA::Database::Macros::Assignment copy_assignment_to_class#insert_assignment_advanced_policy in #{time_diff t8, Time.now}"
        end

        new_assignment_class_id
      rescue PG::Error => e
        raise Errors::DatabaseError.new(nil, e)
      end

      def insert_assignment_mastery_penalty(assignment_mastery_penalty_hashes, new_assignment_class_id)
        t7 = Time.now
        assignment_mastery_penalty_insert_cmd = InsertCmd.new("assignment_mastery_penalty")
        push_assignment_mastery_penalty(assignment_mastery_penalty_hashes, new_assignment_class_id, assignment_mastery_penalty_insert_cmd)
        execute(assignment_mastery_penalty_insert_cmd)
        #puts "Maple::MapleTA::Database::Macros::Assignment copy_assignment_to_class#copy_assignment_mastery_penalties in #{time_diff t7, Time.now}"
      end

      def push_assignment_mastery_penalty(assignment_mastery_penalties, new_assignment_class_id, assignment_mastery_penalty_insert_cmd)
        assignment_mastery_penalties.each do |assignment_mastery_penalty|
          assignment_mastery_penalty_insert_cmd.push(assignment_mastery_penalty, [], {'assignment_class_id' => new_assignment_class_id})
        end
      end

      def insert_assignment_advanced_policy(assignment_advanced_policy_hashes, new_assignment_id, new_assignment_class_id)
        t7 = Time.now
        assignment_advanced_policy_insert_cmd = InsertCmd.new("assignment_advanced_policy")
        push_assignment_advanced_policy(assignment_advanced_policy_hashes, new_assignment_id, new_assignment_class_id, assignment_advanced_policy_insert_cmd)
        execute(assignment_advanced_policy_insert_cmd)
        #puts "Maple::MapleTA::Database::Macros::Assignment copy_assignment_to_class#copy_assignment_mastery_penalties in #{time_diff t7, Time.now}"
      end

      def push_assignment_advanced_policy(assignment_advanced_policies, new_assignment_id, new_assignment_class_id, assignment_advanced_policy_insert_cmd)
        assignment_advanced_policies.each do |assignment_advanced_policy|
          assignment_advanced_policy_insert_cmd.push(assignment_advanced_policy, [], {'assignment_class_id' => new_assignment_class_id, 'assignment_id' => new_assignment_id})
        end
      end

      def insert_assignment_mastery_policy(assignment_mastery_policy_hashes, new_assignment_class_id)
        t6 = Time.now
        assignment_mastery_policy_insert_cmd = InsertCmd.new("assignment_mastery_policy")
        push_assignment_mastery_policy(assignment_mastery_policy_hashes, new_assignment_class_id, assignment_mastery_policy_insert_cmd)
        execute(assignment_mastery_policy_insert_cmd)
        #puts "Maple::MapleTA::Database::Macros::Assignment copy_assignment_to_class#insert_assignment_mastery_policy  in #{time_diff t6, Time.now}"
      end

      def push_assignment_mastery_policy(assignment_mastery_policies, new_assignment_class_id, assignment_mastery_policy_insert_cmd)
        assignment_mastery_policies.each do |assignment_mastery_policy|
          assignment_mastery_policy_insert_cmd.push(assignment_mastery_policy, [], {'assignment_class_id' => new_assignment_class_id})
        end
      end

      def insert_assignment(assignment_hash, new_class_id)
        assignment_insert_cmd = InsertCmd.new("assignment")
        new_assignment_id = exec("SELECT nextval('assignment_id_seq')").first['nextval'].to_i
        push_assignment(assignment_hash, new_assignment_id, new_class_id, {}, assignment_insert_cmd)
        execute(assignment_insert_cmd)
        new_assignment_id
      end

      def update_assignment(assignment)
        assignment_hash = assignment.assignment_hash
        assignment_update_cmd = UpdateCmd.new("assignment", "id=#{assignment.assignmentid}")
        push_assignment(assignment_hash, assignment.assignmentid, assignment.class_id, {}, assignment_update_cmd)
        execute(assignment_update_cmd)
      end

      def push_assignment(assignment, new_assignment_id, new_class_id, overrides, assignment_insert_cmd)
        new_assignment_uid = "#{::UUID.new.generate.to_s}-#{new_class_id}"
        assignment_insert_cmd.push(assignment, %w(lastmodified), {'id' => new_assignment_id, 'classid' => new_class_id, 'uid' => new_assignment_uid}.merge(overrides), {'lastmodified' => 'NOW()'})
      end

      def insert_assignment_class(assignment_class_hash, new_class_id, new_assignment_id)
        t3 = Time.now
        assignment_class_insert_cmd = InsertCmd.new("assignment_class")
        new_assignment_class_id = exec("SELECT nextval('assignment_class_id_seq')").first['nextval'].to_i
        new_order_id = exec("SELECT MAX(order_id) FROM assignment_class WHERE classid=$1", [new_class_id]).first['max'].to_i + 1
        push_assignment_class(assignment_class_hash, new_assignment_class_id, new_class_id, new_assignment_id, new_order_id, {}, assignment_class_insert_cmd)
        execute(assignment_class_insert_cmd)
        new_assignment_class_id
      end

      def update_assignment_class(assignment)
        assignment_class = assignment_class_for_assignmentid(assignment.assignmentid)
        assignment_class_update_cmd = UpdateCmd.new("assignment_class", "id=#{assignment_class['id']}")
        push_assignment_class(assignment.assignment_class_hash, assignment_class['id'], assignment.class_id, assignment.assignmentid, assignment_class['order_id'], {}, assignment_class_update_cmd)
        execute(assignment_class_update_cmd)
      end

      def push_assignment_class(assignment_class, new_assignment_class_id, new_class_id, new_assignment_id, new_order_id, overrides, assignment_class_insert_cmd)
        assignment_class_insert_cmd.push(assignment_class, %w(lastmodified parent), {'id' => new_assignment_class_id, 'classid' => new_class_id, 'assignmentid' => new_assignment_id, 'order_id' => new_order_id}.merge(overrides), {'lastmodified' => 'NOW()'})
      end

      def insert_assignment_policy(assignment_policy_hash, new_assignment_class_id)
        t4 = Time.now
        assignment_policy_insert_cmd = InsertCmd.new("assignment_policy")
        push_assignment_policy(assignment_policy_hash, new_assignment_class_id, assignment_policy_insert_cmd)
        execute(assignment_policy_insert_cmd)
        #puts "Maple::MapleTA::Database::Macros::Assignment copy_assignment_to_class#copy_assignment_policy new assignment class in #{time_diff t4, Time.now}"
      end

      def update_assignment_policy(assignment)
        assignment_policy = assignment_policy_for_assignmentid(assignment.assignmentid)
        assignment_policy_update_cmd = UpdateCmd.new("assignment_policy", "assignment_class_id=#{assignment_policy['assignment_class_id']}")
        push_assignment_policy(assignment.assignment_policy_hash, assignment_policy['assignment_class_id'], assignment_policy_update_cmd)
        execute(assignment_policy_update_cmd)
      end

      def push_assignment_policy(assignment_policy, new_assignment_class_id, assignment_policy_insert_cmd)
        assignment_policy_insert_cmd.push(assignment_policy, %w(), {'assignment_class_id' => new_assignment_class_id})
      end

      def insert_assignment_question_groups(assignment_question_groups, new_assignment_id)
        t5 = Time.now
        assignment_question_group_insert_cmd = InsertCmd.new('assignment_question_group')
        assignment_question_group_map_insert_cmd = InsertCmd.new('assignment_question_group_map')

        new_group_ids = exec("SELECT nextval('assignment_question_group_id_seq') FROM generate_series(1, #{assignment_question_groups.count})")
        assignment_question_groups.each_with_index do |assignment_question_group, index|
          new_group_id = new_group_ids.instance_of?(Array) ? new_group_ids[index]['nextval'] : new_group_ids.getvalue(index, 0)
          raise Errors::DatabaseError.new("Cannot determine new assignment_question_group id") unless new_group_id && new_group_id.to_i > 0

          assignment_question_group_hash = assignment_question_group.hash
          assignment_question_group_hash['order_id'] = index
          push_assignment_question_group(assignment_question_group_hash, new_group_id, new_assignment_id, assignment_question_group_insert_cmd)
          assignment_question_group.map_hashes.each do |assignment_question_group_map_hash|
            push_assignment_question_group_map(assignment_question_group_map_hash, new_group_id, assignment_question_group_map_insert_cmd)
          end
        end

        execute(assignment_question_group_insert_cmd)
        execute(assignment_question_group_map_insert_cmd)
        #puts "Maple::MapleTA::Database::Macros::Assignment copy_assignment_to_class#copy_assignment_question_group in #{time_diff t5, Time.now}"
      end

      def update_assignment_question_groups(assignment)
        assignment_question_group_maps = assignment_question_group_maps(assignment.assignmentid)
        delete_assignment_question_groups(assignment_question_group_maps)

        insert_assignment_question_groups(assignment.assignment_question_groups, assignment.assignmentid)
      end

      def push_assignment_question_group(assignment_question_group_hash, new_group_id, new_assignment_id, assignment_question_group_insert_cmd)
        assignment_question_group_insert_cmd.push(assignment_question_group_hash, [], {'id' => new_group_id, 'assignmentid' => new_assignment_id})
      end

      def push_assignment_question_group_map(assignment_question_group_map_hash, new_group_id, assignment_question_group_map_insert_cmd)
        assignment_question_group_map_insert_cmd.push(assignment_question_group_map_hash, %w(id), {'groupid' => new_group_id})
      end

      # Copy assignment_question_group and assignment_question_group_map
      def push_assignment_question_groups(assignment_question_group_hashes, assignment_question_group_maps_all_hashes, new_group_ids, new_assignment_id, assignment_question_group_insert_cmd, assignment_question_group_map_insert_cmd)

        assignment_question_group_hashes.each_with_index do |assignment_question_group_hash, index|
          new_group_id = new_group_ids.instance_of?(Array) ? new_group_ids[index]['nextval'] : new_group_ids.getvalue(index, 0)
          raise Errors::DatabaseError.new("Cannot determine new assignment_question_group id") unless new_group_id && new_group_id.to_i > 0

          push_assignment_question_group(assignment_question_group_hash, new_group_id, new_assignment_id, assignment_question_group_insert_cmd)

          assignment_question_group_map_hashes = assignment_question_group_maps_all_hashes.select{|a| a['groupid'] == assignment_question_group_hash['id']}
          assignment_question_group_map_hashes.each do |assignment_question_group_map_hash|
            push_assignment_question_group_map(assignment_question_group_map_hash, new_group_id, assignment_question_group_map_insert_cmd)
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
        exec("SELECT * FROM assignment_policy WHERE assignment_class_id=$1", [assignment_class_id]).first
      end

      ##
      # Get the assignment policy database row for a given assignmentid
      def assignment_policy_for_assignmentid(assignmentid)
        raise Errors::DatabaseError.new("Must pass assignmentid") unless assignmentid
        exec("SELECT p.* FROM assignment_policy p left join assignment_class a on a.id = p.assignment_class_id WHERE a.assignmentid=$1", [assignmentid]).first
      end

      ##
      # Get the assignment question group database row for a given assignmentid
      def assignment_question_groups(assignmentid)
        raise Errors::DatabaseError.new("Must pass assignmentid") unless assignmentid
        build_assignment_question_groups(exec("SELECT * FROM assignment_question_group WHERE assignmentid=$1", [assignmentid]))
      end

      ##
      # Get the assignment question group database row for a given assignmentid
      def assignment_question_group_maps(assignmentid)
        raise Errors::DatabaseError.new("Must pass assignmentid") unless assignmentid
        build_assignment_question_group_maps(exec("SELECT m.* FROM assignment_question_group_map m left join assignment_question_group a on a.id = m.groupid WHERE a.assignmentid=$1", [assignmentid]))
      end

      ##
      # Get the assignment object for a given assignment_class_id
      def assignment_obj(assignment_class_id)
        raise Errors::DatabaseError.new("Must pass assignment_class_id") unless assignment_class_id
        assignment_class_hash = assignment_class_by_id(assignment_class_id)
        assignment_policy_hash = assignment_policy(assignment_class_id)
        assignment = Maple::MapleTA::Assignment.new(assignment_class_hash.merge(assignment_policy_hash))
        assignment_question_groups = assignment_question_groups(assignment.assignmentid)
        assignment_question_group_maps = assignment_question_group_maps(assignment.assignmentid)
        assignment_question_groups.each do |group|
          group.assignment_question_group_maps = assignment_question_group_maps.select{|map| map.groupid == group.id}
        end
        assignment.assignment_question_groups = assignment_question_groups
        assignment
      end

      ##
      # Get the assignment database row for a given classid
      def assignment(classid)
        raise Errors::DatabaseError.new("Must pass classid") unless classid
        exec("SELECT * FROM assignment WHERE classid=$1", [classid]).first
      end

      ##
      # Get the assignment database row for a given classid
      def assignment_by_id(assignment_id)
        raise Errors::DatabaseError.new("Must pass assignment_id") unless assignment_id
        exec("SELECT * FROM assignment WHERE id=$1", [assignment_id]).first
      end

      ##
      # Get the assignment_class database row for a given classid
      def assignment_class(classid)
        raise Errors::DatabaseError.new("Must pass classid") unless classid
        exec("SELECT * FROM assignment_class WHERE classid=$1", [classid]).first
      end

      ##
      # Get the assignment_class database row for a given assignment_class_id
      def assignment_class_by_id(assignment_class_id)
        raise Errors::DatabaseError.new("Must pass assignment_class_id") unless assignment_class_id
        exec("SELECT * FROM assignment_class WHERE id=$1", [assignment_class_id]).first
      end

      ##
      # Get the assignment_class database row for a given assignmentid
      def assignment_class_for_assignmentid(assignmentid)
        raise Errors::DatabaseError.new("Must pass assignmentid") unless assignmentid
        exec("SELECT * FROM assignment_class WHERE assignmentid=$1", [assignmentid]).first
      end

      ##
      # Delete the assignment database row for a given assignment_class_id
      def delete_assignment(assignment_class_id)
        assignment_class = assignment_class_by_id(assignment_class_id)
        assignment = assignment_by_id(assignment_class['assignmentid'])
        transaction do
          delete_assignment_class_row(assignment_class)
          delete_assignment_row(assignment)
        end
      end

      def delete_assignment_row(assignment)
        return unless assignment
        delete_assignment_question_groups(assignment_question_group_maps(assignment['id']))
        exec("DELETE FROM assignment WHERE id=$1", [assignment['id']]).first
      end

      def delete_assignment_question_groups(assignment_question_group_maps)
        assignment_question_group_maps.each do |assignment_question_group_map|
          exec("DELETE FROM assignment_question_group_map WHERE id=$1", [assignment_question_group_map.id])
        end
        assignment_question_group_maps.each do |assignment_question_group_map|
          exec("DELETE FROM assignment_question_group WHERE id=$1", [assignment_question_group_map.groupid])
        end
      end

      def delete_assignment_class_row(assignment_class)
        return unless assignment_class
        exec("DELETE FROM assignment_policy WHERE assignment_class_id=$1", [assignment_class['id']]).first
        exec("DELETE FROM assignment_class WHERE id=$1", [assignment_class['id']]).first
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
        assignment_class = exec("SELECT assignmentid, name FROM assignment_class WHERE id=$1", [assignment_class_id]).first
        raise Errors::DatabaseError.new("Cannot find assignment_class with id=#{assignment_class_id}") unless assignment_class && assignment_class['assignmentid']

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

      def time_diff(start, finish)
        ms = (finish - start) * 1000.0
        if(ms < 1000)
          return "#{ms.round} ms"
        end

        sec = ms / 1000.0
        if(sec < 60)
          return "#{sec.round} sec"
        end

        return "#{(sec / 60.0).round} min"
      end

      private

        def build_assignment_question_groups(pg_result)
          pg_result.to_a.map{|assignment_question_group| Maple::MapleTA::AssignmentQuestionGroup.new(assignment_question_group)}
        end

        def build_assignment_question_group_maps(pg_result)
          pg_result.to_a.map{|assignment_question_group_map| Maple::MapleTA::AssignmentQuestionGroupMap.new(assignment_question_group_map)}
        end

    end
  end
end

class Cmd

  def initialize(table_name)
    @table_name = table_name
    @values = []
    @values_sqls = []
    @key_sql = nil
    @keys = []
    @value_placeholders = []
    @start_param = 1
  end

  def push(hash, except=[], override={}, additional_columns=nil)
    cols = sql_cols_for(hash, except, override, @start_param)
    if additional_columns
      cols[:keys].concat(additional_columns.keys)
      cols[:vals].concat(additional_columns.values)
    end
    unless @key_sql
      @key_sql = "#{cols[:keys].join(', ')}"
      @keys = cols[:keys]
      @value_placeholders = cols[:vals]
    end

    @values.concat(cols[:params])
    @values_sqls.push("(#{cols[:vals].join(', ')})")
    @start_param = @start_param + cols[:params].length
  end

  def sql

  end

  def empty?
    @values.empty?
  end

  def values
    @values
  end

  def sql_cols_for(hash, except=[], override={}, startParam=1)
    keys = []
    vals = []
    params = []

    hash.each do |key, val|
      unless except.include?(key)
        keys << key
        vals << "$#{startParam}"
        params << (override.has_key?(key) ? override[key] : val)

        startParam += 1
      end
    end

    {:keys => keys, :vals => vals, :params => params}
  end

end

class InsertCmd < Cmd

  def sql
    "INSERT INTO #{@table_name} (#{@key_sql}) VALUES #{@values_sqls.join(",")}"
  end

end

class UpdateCmd < Cmd

  def initialize(table_name, condition)
    super(table_name)
    @condition = condition
  end

  def sql
    sets = []
    @keys.each_with_index { |key, index| sets.push "#{key}=#{@value_placeholders[index]}"}

    "UPDATE #{@table_name} SET #{sets.join(",")} WHERE #{@condition}"
  end


end