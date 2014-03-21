module Maple::MapleTA
  module Orm
    class AssignmentClass < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment_class] )
      plugin :timestamps, :create => :updated_at, :update => :updated_at
      plugin :nested_attributes

      def_column_alias :class_id,      :classid
      def_column_alias :assignment_id, :assignmentid
      def_column_alias :total_points,  :totalpoints
      def_column_alias :updated_at,    :lastmodified

      many_to_one :assignment, key: [:assignmentid, :classid], primary_key: [:id, :classid] 
      one_to_one :assignment_policy

      plugin :association_dependencies, :assignment_policy => :delete
      plugin :deep_dup

      nested_attributes :assignment_policy

      def before_create
        super
        self.order_id ||=
          self.class.dataset.where(classid: class_id).max(:order_id).to_i + 1
      end
    end
  end
end
