module Maple::MapleTA
  module Orm
    class MasteryPolicy < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment_mastery_policy] )

    end
  end
end
