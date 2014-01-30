module Maple::MapleTA
  module Orm
    class AssignmentClass < ActiveRecord::Base
      include Maple::MapleTA::Orm

      self.table_name = 'assignment_class'

      belongs_to :parent_class, :class_name => 'Maple::MapleTA::Orm::Class', :foreign_key => 'classid'
      belongs_to :master_assignment, :class_name => 'Maple::MapleTA::Orm::Assignment', :foreign_key => 'assignmentid'
      has_one :policy, :class_name => 'Maple::MapleTA::Orm::AssignmentPolicy', :foreign_key => 'assignment_class_id'

    end
  end
end