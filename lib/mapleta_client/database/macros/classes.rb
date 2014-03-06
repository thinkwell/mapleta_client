
module Maple::MapleTA
  module Database::Macros
    module Classes
      def delete_class(cid)
        raise Errors::DatabaseError.new("Must pass cid") unless cid

        dataset[:user_classes].where(classid: cid).delete
        dataset[:classes].where(cid: cid).delete
      end
    end
  end
end
