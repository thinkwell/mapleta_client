
module Maple::MapleTA
  module Database::Macros
    module Question
      def questions_for_assignment_class(assignment_class_id)
        raise Errors::DatabaseError.new("Must pass assignment_class_id") unless assignment_class_id
        exec("Select q.* from question q left join assignment_question_group_map m on m.questionid = q.id left join assignment_question_group a on a.id = m.groupid left join assignment_class c on c.assignmentid = a.assignmentid where c.classid=$1 and q.latestrevision is null", [assignment_class_id])
      end

      def questions_for_class(classid)
        raise Errors::DatabaseError.new("Must pass classid") unless classid
        exec("Select q.* from question q left join classes c on c.cid = q.author or c.parent = q.author where c.cid=$1 and q.latestrevision is null", [classid])
      end
    end
  end
end
