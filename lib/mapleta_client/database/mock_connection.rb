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

      def exec(*args)
        []
      end

      def user_id_for_unique_id(user_unique_id)
        nil
      end

      def copy_assignment_to_class(assignment_class_id, new_class_id)
        new_class_id + 1
      end

      def assignment_name(assignment_class_id, name=nil)
        name
      end

      def test_record(try_id)
        nil
      end

      def questions(question_ids)
        question_ids.map {|id| Maple::MapleTA::Question.new(:id => id, :name => "name_#{id}")}
      end

      def create_assignment(assignment)
        [123, 234]
      end

      def edit_assignment(assignment)
      end

      def destroy_test_record(try_id)
        nil
      end

      def active_test_record(user_unique_id, assignment_class_id)
        nil
      end

      def active_test_record_id(user_unique_id, assignment_class_id)
        nil
      end

      def test_records(user_unique_id, assignment_class_id, start_utc)
        []
      end
    end
  end
end
