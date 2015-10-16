module Maple::MapleTA
  module Orm
    class Question < Base

      self.table_name = 'question'

      has_many :assignment_question_group_maps, :class_name => namespace('AssignmentQuestionGroupMap'), :foreign_key => 'questionid'
      belongs_to :question_header, :class_name => namespace('QuestionHeader'), :primary_key => 'uid', :foreign_key => 'uid'

      def latest_revision_id
        latestrevision || self.id
      end

      def is_latest_revision?
        !latestrevision
      end

      def self.search(classid, search=nil, limit=100, offset=0, group_ids=[])
        if search && search.strip.split(/\s+/).length > 0
          search_conditions = " AND " + search.strip.split(/\s+/).map{|w| " qh.name ~* '.*#{w}.*' "}.join('AND') + " "
        else
          search_conditions = ''
        end
        if group_ids.length > 0
          search_conditions += " AND qg.id IN (#{group_ids.join(',')}) "
        end

        sql = <<-SQL
          SELECT q.id, qh.name, qg.name AS group_name, count(*) OVER() AS full_search_count
          FROM question q
          JOIN question_header qh ON qh.uid = q.uid AND qh.deleted = 'f'
          JOIN question_group_map qgm ON qgm.questionid = q.id
          JOIN question_group qg ON qg.id = qgm.questiongroupid
          LEFT JOIN classes c ON c.cid = q.author OR c.parent = q.author
          WHERE c.cid=#{classid}
          AND q.latestrevision IS NULL
          AND q.deleted = 'f'
          #{search_conditions}
          ORDER BY qg.name, qh.name
          LIMIT #{limit} OFFSET #{offset}
        SQL

        self.connection.execute(sql).to_a

      end

    end
  end
end
