module Maple::MapleTA
  module Orm
    class Question < Sequel::Model( Maple::MapleTA.database_connection.dataset[:question] )
      one_to_many :assignment_question_groups, :key => :questionid
    end
  end
end
