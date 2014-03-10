module Maple::MapleTA
  module Orm
    class Assignment < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment] )

      # belongs_to :parent_class, :class_name => 'Maple::MapleTA::Orm::Class', :foreign_key => 'classid'
      # has_many :class_assignments, :class_name => 'Maple::MapleTA::Orm::AssignmentClass', :foreign_key => 'assignmentid'
    end
  end
end
