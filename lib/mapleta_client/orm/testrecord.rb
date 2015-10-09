module Maple::MapleTA
  module Orm
    class Testrecord < Base

      set_primary_key 'id'
      self.table_name = 'testrecord'

      belongs_to :assignment, :class_name => namespace('Assignment'), :foreign_key => 'assignmentid'
      belongs_to :user, :class_name => namespace('UserProfile'), :foreign_key => 'userid'
      has_many :answersheetitems, :class_name => namespace('Answersheetitem'), :foreign_key => 'testrecordid', :dependent => :destroy

    end
  end
end
