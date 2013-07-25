
module Maple::MapleTA
  module Database::Macros
    module Answersheetitem

      def answer_mathml(offset, min_length, condition)
        raise Errors::DatabaseError.new("Must pass offset") unless offset
        raise Errors::DatabaseError.new("Must pass min_length") unless min_length
        result = exec("select searchableresponsestring from answersheetitem  where searchableresponsestring like '%math%' and searchableresponsestring not like '%mstyle%' and char_length(searchableresponsestring) > $1 #{condition} order by id asc limit 1 offset $2", [min_length, offset]).first
        result ? Maple::MapleTA::Page::BaseQuestion.convert_to_presentation_mathml(result['searchableresponsestring']).gsub("\n", "") : nil
      end

    end
  end
end
