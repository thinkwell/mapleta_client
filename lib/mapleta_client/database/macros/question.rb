
module Maple::MapleTA
  module Database::Macros
    module Question
      def questions_for_assignment_class(assignment_class_id)
        raise Errors::DatabaseError.new("Must pass assignment_class_id") unless assignment_class_id
        build_questions(exec("Select q.* from question q left join assignment_question_group_map m on m.questionid = q.id left join assignment_question_group a on a.id = m.groupid left join assignment_class c on c.assignmentid = a.assignmentid where c.classid=$1 and q.latestrevision is null", [assignment_class_id]))
      end

      def questions(question_ids)
        raise Errors::DatabaseError.new("Must pass question_ids") unless question_ids
        values = question_ids.each_with_index.map{ |x,i| "(" + x.to_s + "," + i.to_s + ")" }.join(",")
        build_questions(exec("Select * from question q join (values#{values}) as x (id, ordering) on q.id = x.id order by x.ordering", []))
      end

      def questions_for_class(classid, search=nil, limit=100, offset=0)
        raise Errors::DatabaseError.new("Must pass classid") unless classid
        sql = questions_for_class_sql(search)
        sql.concat(" group by q.id order by q.name")
        build_questions(exec("Select q.* #{sql} limit #{limit} offset #{offset}", [classid]))
      end

      def questions_for_class_count(classid, search=nil)
        raise Errors::DatabaseError.new("Must pass classid") unless classid
        sql = questions_for_class_sql(search)
        exec("Select count(q.*) #{sql}", [classid]).first()['count'].to_i
      end

      private

      def questions_for_class_sql(search)
        if search && search.strip.split(/\s+/).length > 0
          search_conditions = "AND " + search.strip.split(/\s+/).map{|w| " q.name ~* '.*#{w}.*' "}.join('AND')
        else
          search_conditions = ''
        end

        <<-SQL
          FROM question q
          JOIN question_header qh ON qh.uid = q.uid AND qh.deleted = 'f'
          LEFT JOIN classes c ON c.cid = q.author OR c.parent = q.author
          WHERE c.cid=$1
          AND q.latestrevision IS NULL
          AND q.deleted = 'f'
          #{search_conditions}
        SQL
      end

      def build_questions(pg_result)
        pg_result.to_a.map{|question| Maple::MapleTA::Question.new(question)}
      end
    end
  end
end
