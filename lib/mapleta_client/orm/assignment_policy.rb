module Maple::MapleTA
  module Orm
    class AssignmentPolicy < Sequel::Model( Maple::MapleTA.database_connection.dataset[:assignment_policy] )
      unrestrict_primary_key

      set_primary_key :assignment_class_id

      MODE_PROCTORED_TEST     = 0
      MODE_UNPROCTORED_TEST   = 1
      MODE_PRACTICE           = 2
      MODE_MASTERY_ASSIGNMENT = 3
      MODE_STUDY_SESSION      = 4

      def recorded?
        self.class.recorded_modes.include?(self.mode)
      end

      def self.recorded_modes
        [MODE_PROCTORED_TEST, MODE_UNPROCTORED_TEST, MODE_MASTERY_ASSIGNMENT]
      end
    end
  end
end
