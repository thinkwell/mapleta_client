
module Maple::MapleTA
  module Database::Macros
    module Classes
      def delete_class(cid)
        Orm::Class.with_pk!(cid).destroy
      end
    end
  end
end
