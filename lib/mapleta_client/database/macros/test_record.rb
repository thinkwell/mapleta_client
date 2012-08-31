
module Maple::MapleTA
  module Database::Macros
    module TestRecord

      def destroy_test_record(try_id)
        raise Errors::DatabaseError.new("Must pass try_id") unless try_id
        test_record = exec("SELECT * FROM testrecord WHERE id=$1", [try_id]).first
        raise Errors::DatabaseError.new("Cannot find test record with id=#{try_id}") unless test_record && test_record['id']
        transaction do
          exec("DELETE FROM answersheetitem_grade WHERE answersheetitemid IN (SELECT id FROM answersheetitem WHERE testrecordid=$1)", [try_id])
          exec("DELETE FROM answersheetitem WHERE testrecordid=$1", [try_id])
          exec("DELETE FROM testrecord WHERE id=$1", [try_id])
        end
      rescue PG::Error => e
        raise Errors::DatabaseError.new(nil, e)
      end
    end
  end
end
