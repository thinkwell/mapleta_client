module Maple::MapleTA
  module Orm
    class Answersheetitem < Base

      set_primary_key 'id'
      self.table_name = 'answersheetitem'

      belongs_to :testrecord, :class_name => 'Maple::MapleTA::Orm::Testrecord', :foreign_key => 'testrecordid'

    end
  end
end