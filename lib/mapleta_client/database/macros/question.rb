
module Maple::MapleTA
  module Database::Macros
    module Question
      def questions_for_assignment_class(assignment_class_id)
        unless assignment_class_id
          raise Errors::DatabaseError.new("Must pass assignment_class_id") 
        end

        query = <<-SQL
          select q.* from question q
            left join assignment_question_group_map m
              on m.questionid = q.id
            left join assignment_question_group a
              on a.id = m.groupid
            left join assignment_class c
              on c.assignmentid = a.assignmentid
            where c.classid=? and q.latestrevision is null
        SQL

        exec query, [assignment_class_id]
      end
    end
  end
end
