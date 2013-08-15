
module Maple::MapleTA
  module Database::Macros
    module Question
      def questions_for_assignment_class(assignment_class_id)
        raise Errors::DatabaseError.new("Must pass assignment_class_id") unless assignment_class_id
        exec("Select q.* from question q left join assignment_question_group_map m on m.questionid = q.id left join assignment_question_group a on a.id = m.groupid left join assignment_class c on c.assignmentid = a.assignmentid where c.classid=$1 and q.latestrevision is null", [assignment_class_id])
      end

      def questions(question_ids)
        raise Errors::DatabaseError.new("Must pass question_ids") unless question_ids
        exec("Select * from question where id IN (#{question_ids.join(",")})", [])
      end

      def questions_for_class(classid, search=nil, limit=100, offset=0)
        raise Errors::DatabaseError.new("Must pass classid") unless classid
        sql = questions_for_class_sql(search)
        exec("Select q.* #{sql} limit #{limit} offset #{offset}", [classid]).to_a
      end

      def questions_for_class_count(classid, search=nil)
        raise Errors::DatabaseError.new("Must pass classid") unless classid
        sql = questions_for_class_sql(search)
        exec("Select count(q.*) #{sql}", [classid]).first()['count'].to_i
      end

      private

      def questions_for_class_sql(search)
        sql = "from question q left join classes c on c.cid = q.author or c.parent = q.author where c.cid=$1 and q.latestrevision is null"
        sql.concat(" and (q.name like '%#{search}%' or q.questiontext like '%#{search}%')") if search
        sql.concat(" group by q.id order by q.id asc")
        sql
      end
    end
  end
end
