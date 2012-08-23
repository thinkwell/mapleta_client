module Maple::MapleTA
  module Database
    class MockConnection
      def initialize(*args)
        @finsihed = false
      end

      def finish
        @finished = true
      end
      alias :close :finish

      def status
        PG::CONNECTION_OK
      end

      def finished?
        @finished
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
