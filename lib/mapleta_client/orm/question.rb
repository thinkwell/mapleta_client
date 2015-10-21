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

          search_string = ''
          search_conditions = []

          # Split search string to possible sequence and name
          split_search = search.to_s.strip.match(/((P\.|[0-9]*\.*){0,4})(.*)/)
          sequence = split_search ? split_search[1] : ''
          keywords = split_search ? split_search[3].strip.split(/\s+/) : ''

          # Transform sequence into pattern matching regex to allow matches on sequence numbers with leading zeros
          sequence = sequence.split('.').map{|i| "0*#{i}"}.join('\.')

          # Search for sequence number
          search_conditions << " qg.name ~* '#{sequence}' " unless sequence.blank?
          # Split search string to individual keywords to search for
          search_conditions << " " + keywords.map{|w| " qg.name ~* '.*#{Regexp.escape(w)}.*' "}.join('AND') + " " if keywords.length > 0 && sequence.blank?

          search_string = "(#{search_conditions.join(' AND ')})"

          # Search question name using keywords only
          if keywords.length > 0
            join_keyword = sequence.blank? ? 'OR' : 'AND'
            search_string += " #{join_keyword} (" + keywords.map{|w| " qh.name ~* '.*#{Regexp.escape(w)}.*' "}.join('AND') + ") "
          end
          search_string = " AND (#{search_string})"
        else
          search_string = ''
        end
        if group_ids.length > 0
          search_string += " AND qg.id IN (#{group_ids.join(',')}) "
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
          AND q.info !~* '.*active=no.*'
          AND qh.name !~ '.*ADAPTIVE.*'
          #{search_string}
          ORDER BY qg.name, qh.name
          LIMIT #{limit} OFFSET #{offset}
        SQL

        self.connection.execute(sql).to_a

      end

    end
  end
end
