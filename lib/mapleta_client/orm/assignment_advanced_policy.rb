# Use and_id to group advanced policies into AND conditions. Use or_id to order OR conditions within groups.

module Maple::MapleTA
  module Orm
    class AssignmentAdvancedPolicy < ActiveRecord::Base
      include Maple::MapleTA::Orm

      set_primary_key 'assignment_class_id'
      self.table_name = 'assignment_advanced_policy'

      belongs_to :assignment_class, :class_name => 'Maple::MapleTA::Orm::AssignmentClass', :foreign_key => 'assignment_class_id'
      belongs_to :assignment, :class_name => 'Maple::MapleTA::Orm::Assignment', :foreign_key => 'assignment_id'

    end
  end
end