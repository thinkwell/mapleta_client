
module Maple::MapleTA
  module Database::Macros
    module TestRecord

      def test_record(try_id)
        raise Errors::DatabaseError.new("Must pass try_id") unless try_id
        exec("SELECT * FROM testrecord WHERE id=$1", [try_id]).first
      end

      def destroy_test_record(try_id)
        test_record = test_record(try_id)
        raise Errors::DatabaseError.new("Cannot find test record with id=#{try_id}") unless test_record && test_record['id']
        transaction do
          exec("DELETE FROM answersheetitem_grade WHERE answersheetitemid IN (SELECT id FROM answersheetitem WHERE testrecordid=$1)", [try_id])
          exec("DELETE FROM answersheetitem WHERE testrecordid=$1", [try_id])
          exec("DELETE FROM testrecord WHERE id=$1", [try_id])
        end
      rescue PG::Error => e
        raise Errors::DatabaseError.new(nil, e)
      end

      def active_test_record(user_unique_id, assignment_class_id)
        raise Errors::DatabaseError.new("Must pass user_unique_id") unless user_unique_id
        raise Errors::DatabaseError.new("Must pass assignment_id") unless assignment_class_id

        user = exec("SELECT * FROM user_profiles WHERE uid=$1", [user_unique_id]).first
        raise Errors::DatabaseError.new("Cannot find user for unique_id=#{user_unique_id}") unless user
        user_id = user['id']

        assignment_class = exec("SELECT * FROM assignment_class WHERE id=$1", [assignment_class_id]).first
        assignment = exec("SELECT * FROM assignment WHERE id=$1", [assignment_class['assignmentid']]).first if assignment_class && assignment_class['assignmentid']
        raise Errors::DatabaseError.new("Cannot find assignment for assignment_class_id=#{assignment_class_id}") unless assignment
        assignment_id = assignment['id']

        exec("SELECT * FROM testrecord WHERE userid=$1 AND assignmentid=$2 AND active='t'", [user_id, assignment_id]).first
      rescue PG::Error => e
        raise Errors::DatabaseError.new(nil, e)
      end

      def active_test_record_id(user_unique_id, assignment_class_id)
        test_record = active_test_record(user_unique_id, assignment_class_id)
        test_record ? test_record['id'] : nil
      end
    end
  end
end
