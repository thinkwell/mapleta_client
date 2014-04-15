module Maple::MapleTA
  module Orm
    class AssignmentClass < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment_class] )
      plugin :timestamps, :create => :updated_at, :update => :updated_at
      plugin :nested_attributes

      def_column_alias :class_id,      :classid
      def_column_alias :assignment_id, :assignmentid
      def_column_alias :total_points,  :totalpoints
      def_column_alias :updated_at,    :lastmodified

      many_to_one :assignment, :key => :assignmentid
      one_to_one  :assignment_policy
      one_to_one  :advanced_policy

      plugin :association_dependencies, :assignment_policy => :delete,
        :advanced_policy => :delete

      plugin :deep_dup

      nested_attributes :assignment_policy
      nested_attributes :advanced_policy, :unmatched_pk => :create, :destroy => true

      def before_create
        super
        self.order_id ||=
          self.class.dataset.where(:classid => class_id).max(:order_id).to_i + 1
      end

      def recorded?
        self.assignment_policy.recorded?
      end

      def copy(options = {})
        db.transaction do

          new_class_id = options[:class_id] || self.class_id
          new_assignment_class =
            self.deep_dup :assignment_policy, :assignment => {
              :assignment_question_groups => :assignment_question_group_maps
            }

          new_assignment_class.class_id = new_class_id

          new_assignment_name = options[:name] || self.name
          new_assignment_name = new_assignment_name + ' - COPY' if new_class_id == self.class_id && options[:name].nil?
          new_assignment_class.name = new_assignment_class.assignment.name = new_assignment_name

          new_start_time = options[:start_time]
          new_start_time = self.assignment_policy.start_time if new_class_id == self.class_id && !options.has_key?(:start_time)
          new_assignment_class.assignment_policy.start_time = new_start_time

          new_end_time = options[:end_time]
          new_end_time = self.assignment_policy.end_time if new_class_id == self.class_id && !options.has_key?(:end_time)
          new_assignment_class.assignment_policy.end_time = new_end_time

          new_assignment_class.assignment.class_id = new_class_id
          new_assignment_class.assignment.uid = "#{UUID.new.generate.to_s}-#{new_class_id}"
          new_assignment_class.save

          if adv_policy = self.advanced_policy
            new_adv_policy_attrs = adv_policy.to_hash.merge(:assignment_class_id => new_assignment_class.id)
            new_assignment_class.advanced_policy = AdvancedPolicy.new(new_adv_policy_attrs).save
          end

          new_assignment_class
        end
      end
    end
  end
end
