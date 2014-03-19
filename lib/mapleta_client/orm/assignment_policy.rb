module Maple::MapleTA
  module Orm
    class AssignmentPolicy < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment_policy] )
      unrestrict_primary_key

      set_primary_key :assignment_class_id
    end
  end
end
