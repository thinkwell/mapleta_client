
module Maple::MapleTA
  module Database::Macros
    module Classes
      def delete_class(cid)
        raise Errors::DatabaseError.new("Must pass cid") unless cid
        user_class = exec("DELETE FROM user_classes WHERE classid=$1", [cid]).first
        clazz = exec("DELETE FROM classes WHERE cid=$1", [cid]).first
        [user_class && user_class['id'].to_i, clazz && clazz['id'].to_i]
      end
    end
  end
end
