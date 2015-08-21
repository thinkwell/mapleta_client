module Maple::MapleTA
  module Orm
    class Testrecord < ActiveRecord::Base
      include Maple::MapleTA::Orm

      set_primary_key 'id'
      self.table_name = 'testrecord'

      belongs_to :assignment, :class_name => 'Maple::MapleTA::Orm::Assignment', :foreign_key => 'assignmentid'
      has_many :answersheetitems, :class_name => 'Maple::MapleTA::Orm::Answersheetitem', :foreign_key => 'testrecordid', :dependent => :destroy
      belongs_to :user, :class_name => 'Maple::MapleTA::Orm::UserProfile', :foreign_key => 'userid'
    end
  end
end
