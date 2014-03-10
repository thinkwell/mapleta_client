module Maple::MapleTA
  module Orm
    class Author < Sequel::Model( Maple::MapleTA.database_connection.dataset[:author] )

    end
  end
end
