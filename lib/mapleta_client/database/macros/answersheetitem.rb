
module Maple::MapleTA
  module Database::Macros
    module Answersheetitem

      def answer_mathml(offset, min_length)
        raise Errors::DatabaseError.new("Must pass offset") unless offset
        raise Errors::DatabaseError.new("Must pass min_length") unless min_length
        result = exec("select searchableresponsestring from answersheetitem  where searchableresponsestring like '%math%' and searchableresponsestring not like '%mstyle%' and char_length(searchableresponsestring) > $1 order by id asc limit 1 offset $2", [min_length, offset]).first
        result ? result['searchableresponsestring'] : nil
      end

    end
  end
end
