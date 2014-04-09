
module Maple::MapleTA
  module Database::Macros
    module User
      def user_id_for_unique_id(user_unique_id)
        raise Errors::DatabaseError.new("Must pass user_unique_id") unless user_unique_id
        user = exec("SELECT * FROM user_profiles WHERE uid=?", user_unique_id).first
        user && user['id'].to_i
      end
    end
  end
end
