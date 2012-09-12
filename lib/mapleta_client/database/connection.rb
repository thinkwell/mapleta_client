require 'pg'

module Maple::MapleTA
  module Database
    class Connection < ::PG::Connection
      include Macros::Assignment
      include Macros::User
      include Macros::TestRecord

      private

      def sql_cols_for(hash, except=[], override={}, startParam=1)
        keys = []
        vals = []
        params = []

        hash.each do |key, val|
          unless except.include?(key)
            keys << key
            vals << "$#{startParam}"
            params << (override.has_key?(key) ? override[key] : val)

            startParam += 1
          end
        end

        {:keys => keys.join(', '), :vals => vals.join(', '), :params => params}
      end

    end
  end
end
