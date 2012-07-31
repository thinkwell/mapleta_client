module Maple::MapleTA
  module Database
    class MockConnection
      def initialize(*args)
      end

      def status
        PG::CONNECTION_OK
      end

      def copy_assignment_to_class(assignment_class_id, new_class_id)
        new_class_id + 1
      end

      def assignment_name(assignment_class_id, name=nil)
        name
      end
    end
  end
end
