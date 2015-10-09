module Maple::MapleTA
  module Orm
    class AnswersheetitemGrade < Base

      set_primary_key 'id'
      self.table_name = 'answersheetitem_grade'

      belongs_to :answersheetitem, :class_name => namespace('Answersheetitem'), :foreign_key => 'answersheetitemid'

    end
  end
end