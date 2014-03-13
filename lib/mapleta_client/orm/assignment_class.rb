module Maple::MapleTA
  module Orm
    class AssignmentClass < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment_class] )
      plugin :timestamps, :create => :updated_at, :update => :updated_at

      def_column_alias :class_id,      :classid
      def_column_alias :assignment_id, :assignmentid
      def_column_alias :updated_at,    :lastmodified
      
      def before_create
        super
        self.order_id ||=
          self.class.dataset.where(classid: class_id).max(:order_id).to_i + 1
      end
    end
  end
end
