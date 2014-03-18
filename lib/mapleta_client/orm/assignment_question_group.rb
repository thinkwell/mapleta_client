module Maple::MapleTA
  module Orm
    class AssignmentQuestionGroup < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment_question_group] )
    end
  end
end
