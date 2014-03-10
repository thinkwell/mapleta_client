module Maple::MapleTA
  module Orm
    class UserClass < Sequel::Model( Maple::MapleTA.database_connection.dataset[:user_classes] )

    end
  end
end
