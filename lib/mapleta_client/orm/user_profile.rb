module Maple::MapleTA
  module Orm
    class UserProfile < Base

      set_primary_key 'id'
      self.table_name = 'user_profiles'

      has_many :testrecords, :class_name => 'Maple::MapleTA::Orm::Testrecord', :foreign_key => 'userid'
    end
  end
end
