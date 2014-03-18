module Maple::MapleTA
  module Orm
    class AssignmentQuestionGroup < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment_question_group] )
      plugin :nested_attributes

      many_to_one :assignment, :key => :assignmentid
      one_to_many :assignment_question_group_maps, key: :groupid

      nested_attributes :assignment_question_group_maps
    end
  end
end
