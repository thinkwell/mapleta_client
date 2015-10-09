module Maple::MapleTA
  module Orm
    class StudentAssignmentPermission < Base

      self.table_name = 'student_assignment_permissions'

      belongs_to :user_profile, :class_name => namespace('UserProfile'), :foreign_key => 'userid'
      belongs_to :assignment, :class_name => namespace('Assignment'), :foreign_key => 'assignmentid'
      belongs_to :parent_class, :class_name => namespace('Class'), :foreign_key => 'classid'

    end
  end
end
