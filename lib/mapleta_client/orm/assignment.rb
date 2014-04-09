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

      one_to_many  :assignment_classes,         :key => :assignmentid
      one_to_many  :assignment_question_groups, :key => :assignmentid
      many_to_many :assignment_question_group_maps, :join_table => :assignment_question_group, :left_key => :assignmentid, :right_key => :id, :right_primary_key => :groupid

      plugin :association_dependencies, :assignment_classes => :destroy, :assignment_question_groups => :destroy


      nested_attributes :assignment_classes
      nested_attributes :assignment_question_groups, :destroy => true

      def self.property(name, opts)
        type    = opts[:type]
        default = opts[:default]

        define_method "#{name}=" do |value|
          value = type ? self.class.db.typecast_value(type, value) : value
          instance_variable_set "@#{name}", value
        end

        define_method name do
          if instance_variable_defined?("@#{name}")
            instance_variable_get("@#{name}")
          else
            default
          end
        end
      end

      attr_accessor :class_name
      attr_accessor :policy

      property :show_current_grade, :type => :boolean, :default => false
      property :insession_grade,    :type => :boolean, :default => false
      property :reworkable,         :type => :boolean, :default => true
      property :printable,          :type => :boolean, :default => false
      property :show_final_grade_feedback, :default => ''
      property :mode,             :type => :integer
      property :mode_description, :from => :modeDescription
      property :passing_score,    :type => :integer
      property :weight,           :type => :float
      property :start,            :type => :time_from_ms
      property :end,              :type => :time_from_ms
      property :time_limit,       :type => :integer
      property :questions,        :default => []

      alias passingScore  passing_score
      alias passingScore= passing_score=
      alias timeLimit     time_limit
      alias timeLimit=    time_limit=
      alias classId       class_id
      alias classId=      class_id=
      alias totalPoints   totalpoints
      alias totalPoints=  totalpoints=
    end
  end
end
