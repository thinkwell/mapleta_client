module Maple::MapleTA
  module Orm
    class Assignment < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment] )
      # TODO: restrict
      unrestrict_primary_key

      # Todo: spec, check time zone
      plugin :timestamps, :create => :updated_at, :update => :updated_at
      plugin :nested_attributes

      def_column_alias :class_id,     :classid
      def_column_alias :total_points, :totalpoints
      def_column_alias :updated_at,   :lastmodified

      one_to_one  :assignment_class, key: [:assignmentid, :classid], primary_key: [:id, :classid]
      one_to_many :assignment_question_groups, key: :assignmentid

      nested_attributes :assignment_class
      nested_attributes :assignment_question_groups

      attr_accessor :questions

      #assignment policy
      attr_accessor :show_current_grade, :reworkable, :printable,
        :insession_grade, :mode, :show_final_grade_feedback, :time_limit,
        :passing_score

      # questions
      attr_accessor :mode_description

      # unknown
      attr_accessor :weight, :policy


      def assignment_question_group_hashes(questions = self.questions)
        questions.map { |question| {"id" => nil, "assignmentid" => nil, "name" => question.name, "order_id" => 0} }
      end

      def assignment_question_group_map_hashes(questions = self.questions)
        questions.map { |question| {"groupid" => nil, "questionid" => question.id, "question_uid" => question.uid} }
      end



      def assignment_class_hash
        {"name" => name, "totalpoints" => total_points, "weighting" => weighting}
      end

      def assignment_policy_hash
        {
         "show_current_grade" => show_current_grade,
         "insession_grade" => insession_grade,
         "reworkable" => reworkable,
         "printable" => printable,
         "mode" => mode || 0,
         "show_final_grade_feedback" => show_final_grade_feedback
        }
      end

      def assignment_mastery_policy_hashes
        []
      end

      def assignment_mastery_penalty_hashes
        []
      end

      def assignment_advanced_policy_hashes
        []
      end

      def include_questionid?(questionid)
        questions.map{ |question| question['id'] }.include?(questionid)
      end

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
