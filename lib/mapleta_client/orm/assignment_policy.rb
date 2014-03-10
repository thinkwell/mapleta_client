module Maple::MapleTA
  module Orm
    class AssignmentPolicy < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment_policy] )
      set_primary_key :assignment_class_id
      # belongs_to :assignment_class, :class_name => 'Maple::MapleTA::Orm::AssignmentClass', :foreign_key => 'assignment_class_id'
    end
  end
end
