module Maple::MapleTA
  module Orm
    class QuestionHeader < Base

      self.table_name = 'question_header'
      self.primary_key = 'id'
      
      has_many :questions, :class_name => namespace('Question'), :primary_key => 'uid', :foreign_key => 'uid'

    end
  end
end
