require 'pg'

module Maple::MapleTA
  module Database
    class Connection
      include Macros::Assignment
      include Macros::User
      include Macros::TestRecord
      include Macros::Classes
      include Macros::Question
      include Macros::Answersheetitem

      attr_reader :dataset

      def initialize(settings)
        @dataset = Sequel.connect settings
      end

      def exec(sql, *values)
        dataset.fetch( sql, *values.flatten ).map do |row|
          row.keys.each { |key| row[key.to_s] = row.delete(key) }

          hash = Hash.new { |hash, key| 
            if Symbol === key 
              raise 'HELL'
              # warn "Accessing results using symbol keys is deprecated"
              hash[key.to_s] 
            end
          }

          hash.merge! row
          hash
        end
      end

      def transaction(&block)
        dataset.transaction &block
      end
    end
  end
end
