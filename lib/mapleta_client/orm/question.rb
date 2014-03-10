module Maple::MapleTA
  module Orm
    class Question < Sequel::Model( Maple::MapleTA.database_connection.dataset[:question] )

      # TODO: hack
      def [] key
        String === key ? super(key.to_sym) : super
      end
    end
  end
end
