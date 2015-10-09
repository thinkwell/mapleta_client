module Maple::MapleTA
  module Orm
    class Answersheetitem < Base

      set_primary_key 'id'
      self.table_name = 'answersheetitem'

      belongs_to :testrecord, :class_name => namespace('Testrecord'), :foreign_key => 'testrecordid'
      has_many :answersheetitem_grades, :class_name => namespace('AnswersheetitemGrade'), :foreign_key => 'answersheetitemid', :dependent => :destroy
      has_many :hint_penalties, :class_name => namespace('HintPenalty'), :foreign_key => 'answersheetitemid', :dependent => :destroy

    end
  end
end
