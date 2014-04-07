module Maple::MapleTA
  module Orm
    class Assignment < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment] )
      # TODO: restrict
      unrestrict_primary_key

      # Todo: spec, check time zone
      plugin :timestamps, :create => :updated_at, :update => :updated_at
      plugin :nested_attributes
      plugin :deep_dup

      def_column_alias :class_id,     :classid
      def_column_alias :total_points, :totalpoints
      def_column_alias :updated_at,   :lastmodified

      one_to_many  :assignment_classes,         :key => [:assignmentid, :classid], :primary_key => [:id, :classid]
      one_to_many  :assignment_question_groups, :key => :assignmentid
      many_to_many :assignment_question_group_maps, :join_table => :assignment_question_group, :left_key => :assignmentid, :right_key => :id, :right_primary_key => :groupid

      plugin :association_dependencies, :assignment_classes => :destroy, :assignment_question_groups => :destroy


      nested_attributes :assignment_classes
      nested_attributes :assignment_question_groups, :destroy => true

      attr_accessor :questions

      #assignment policy
      attr_accessor :show_current_grade, :reworkable, :printable,
        :insession_grade, :mode, :show_final_grade_feedback, :time_limit,
        :passing_score

      # questions
      attr_accessor :mode_description

      # unknown
      attr_accessor :weight, :policy

      attr_accessor :class_name


      # Movable
      def launch(connection, external_data=nil, view_opts={})
        raise Errors::MapleTAError, "Connection class id (#{connection.class_id}) doesn't match assignment class id (#{self.class_id})" unless self.class_id == connection.class_id.to_i

        params = {
          'wsExternalData' => external_data,
          'className' => class_name,
          'testName' => name,
          'testId' => id,
        }

        page connection.launch('assignment', params), connection, view_opts
      end

      private
      def page(mechanize_page, connection, view_opts)
        Maple::MapleTA.Page(mechanize_page, view_opts)
      end
    end
  end
end
