module Maple::MapleTA
  module Orm
    class QuestionGroup < Base

      self.table_name = 'question_group'

      has_one :parent, :class_name => namespace('QuestionGroup'), :primary_key => 'parent', :foreign_key => 'id'
      has_many :groups, :class_name => namespace('QuestionGroup'), :foreign_key => 'parent'

    end
  end
end