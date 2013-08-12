
module Maple::MapleTA
  module Database::Macros
    module Answersheetitem

      def answer_mathml(offset, min_length, condition)
        raise Errors::DatabaseError.new("Must pass offset") unless offset
        raise Errors::DatabaseError.new("Must pass min_length") unless min_length
        where = "where searchableresponsestring like '%math%' and searchableresponsestring not like '%mstyle%' and char_length(searchableresponsestring) > $1 #{condition}"
        count = exec("select count(*) from answersheetitem #{where}", [min_length]).first
        result = exec("select searchableresponsestring from answersheetitem #{where} order by id asc limit 1 offset $2", [min_length, offset]).first
        result ? [count['count'], Maple::MapleTA::Page::BaseQuestion.convert_to_presentation_mathml(result['searchableresponsestring']).gsub("\n", "")] : nil
      end

    end
  end
end
