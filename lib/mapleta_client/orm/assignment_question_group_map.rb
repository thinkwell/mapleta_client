module Maple::MapleTA
  module Orm
    class AssignmentQuestionGroupMap < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment_question_group_map] )
      many_to_one :assignment_question_group, :key => :groupid
      # many_to_one :question, key: :questionid

      def_column_alias :question_id, :questionid
      def_column_alias :group_id, :groupid
    end
  end
end
