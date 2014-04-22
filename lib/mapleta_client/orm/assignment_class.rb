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
      one_to_many  :advanced_policies

      plugin :association_dependencies, :assignment_policy => :delete, :advanced_policies => :delete

      plugin :deep_dup

      nested_attributes :assignment_policy
      nested_attributes :advanced_policies, :unmatched_pk => :create, :destroy => true

      def before_create
        super
        self.order_id ||=
          self.class.dataset.where(:classid => class_id).max(:order_id).to_i + 1
      end

      def recorded?
        assignment_policy.recorded?
      end

      # retake policy is defined using advanced policy along with other unrelated restrictions, retrieve it for convenience
      def retake_policies
        advanced_policies.select{|p| p.assignment_id == self.assignment_id && p.has == false && (1..5).include?(p.keyword)}
      end

      def retake_policy
        retake_policies.first
      end

      def max_attempts
        retake_policy.try(:keyword) || false
      end

      def max_attempts=(attempts)
        if !retake_policy && (1..5).include?(attempts)
          max_or_id = advanced_policies.max_by(&:or_id).try(:or_id)
          self.advanced_policies_attributes = [{
            :assignment_class_id => self.id,
            :assignment_id       => self.assignment_id,
            :keyword             => attempts,
            :and_id              => 0,
            :or_id               => max_or_id ? (max_or_id + 1) : 0,
            :has                 => false,
          }]
        elsif (1..5).include?(attempts)
          retake_policies.each{ |p| p.keyword = attempts; p.save }
        elsif !attempts
          retake_policies.each{ |p| p.delete }
        end
        save
        max_attempts
      end

      def copy(options = {})
        db.transaction do

          new_class_id = options[:class_id] || self.class_id
          copying_to_the_same_class = (new_class_id == self.class_id)

          new_assignment_class =
            self.deep_dup :assignment_policy, :assignment => {
              :assignment_question_groups => :assignment_question_group_maps
            }

          new_assignment_class.class_id = new_class_id

          new_assignment_name = options[:name] || self.name
          new_assignment_name = new_assignment_name + ' - COPY' if copying_to_the_same_class && options[:name].nil?
          new_assignment_class.name = new_assignment_class.assignment.name = new_assignment_name

          new_start_time = options[:start_time]
          new_start_time = self.assignment_policy.start_time if copying_to_the_same_class && !options.has_key?(:start_time)
          new_assignment_class.assignment_policy.start_time = new_start_time

          new_end_time = options[:end_time]
          new_end_time = self.assignment_policy.end_time if copying_to_the_same_class && !options.has_key?(:end_time)
          new_assignment_class.assignment_policy.end_time = new_end_time

          new_assignment_class.assignment.class_id = new_class_id
          new_assignment_class.assignment.uid = "#{UUID.new.generate.to_s}-#{new_class_id}"

          new_assignment_class.save

          self.advanced_policies.each do |ap|

            # Policy refers to another assignment in the same class, keep the assignment id reference
            if copying_to_the_same_class && ap.assignment_id != self.assignment_id
              new_ap_attrs = ap.to_hash.merge(:assignment_class_id => new_assignment_class.id)

            # Policy refers to its own assignment, update assignment reference with new id
            elsif ap.assignment_id == self.assignment_id
              new_ap_attrs = ap.to_hash.merge(:assignment_class_id => new_assignment_class.id,
                                              :assignment_id => new_assignment_class.assignment_id)

            # Policy refers to another assignment from another class, ignore it
            else
              new_ap_attrs = nil
            end

            new_assignment_class.advanced_policies << AdvancedPolicy.new(new_ap_attrs).save if new_ap_attrs
          end

          new_assignment_class.save

          new_assignment_class
        end
      end
    end
  end
end
