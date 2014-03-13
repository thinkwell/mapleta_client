module Maple::MapleTA
  module Orm
    class AssignmentClass < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment_class] )
      unrestrict_primary_key

      plugin :timestamps, :create => :updated_at, :update => :updated_at

      def_column_alias :updated_at,    :lastmodified
      def_column_alias :class_id,      :classid
      def_column_alias :assignment_id, :assignmentid

      # belongs_to :parent_class, :class_name => 'Maple::MapleTA::Orm::Class', :foreign_key => 'classid'
      # belongs_to :master_assignment, :class_name => 'Maple::MapleTA::Orm::Assignment', :foreign_key => 'assignmentid'
      # has_one :policy, :class_name => 'Maple::MapleTA::Orm::AssignmentPolicy', :foreign_key => 'assignment_class_id'
    end
  end
end
