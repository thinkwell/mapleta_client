module Maple::MapleTA
  module Orm
    class HintPenalty < Base

      self.primary_key = 'id'
      self.table_name = 'hint_penalty'

      belongs_to :answersheetitem, :class_name => namespace('Answersheetitem'), :foreign_key => 'answersheetitemid'

    end
  end
end