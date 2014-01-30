module Maple::MapleTA
  module Orm
    class AssignmentPolicy < ActiveRecord::Base
      include Maple::MapleTA::Orm

      set_primary_key 'assignment_class_id'
      self.table_name = 'assignment_policy'

      belongs_to :assignment_class, :class_name => 'Maple::MapleTA::Orm::AssignmentClass', :foreign_key => 'assignment_class_id'

    end
  end
end