module Maple::MapleTA
  module Orm
    class QuestionGroup < Base

      self.table_name = 'question_group'
      self.primary_key = 'id'
      
      has_one :parent_group, :class_name => namespace('QuestionGroup'), :primary_key => 'parent', :foreign_key => 'id'
      has_many :question_groups, :class_name => namespace('QuestionGroup'), :foreign_key => 'parent'

      def all_child_ids
        @all_child_ids ||= self.question_groups.map{|g| g.all_child_ids}.flatten.unshift(self.id)
      end

    end
  end
end
