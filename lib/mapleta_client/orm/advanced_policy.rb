module Maple::MapleTA
  module Orm
    class AdvancedPolicy < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment_advanced_policy] )
      unrestrict_primary_key
      set_primary_key [:assignment_class_id, :and_id, :or_id]
      many_to_one :assignment_class
    end
  end
end
