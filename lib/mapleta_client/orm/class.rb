module Maple::MapleTA
  module Orm
    class Class < Sequel::Model( Maple::MapleTA.database_connection.dataset[:classes] )

      set_primary_key :cid
      alias id pk

      one_to_many :user_classes, :class => Orm::UserClass, :key => :classid

      plugin :association_dependencies, :user_classes => :delete
    end
  end
end
