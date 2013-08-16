require 'mechanize'
require 'logger'

module Maple::MapleTA
  class AssignmentQuestionGroup
    include HashInitialize
    property :id,                 :type => :integer
    property :assignmentid,       :type => :integer
    property :name
    property :order_id, :type => :integer, :default => 0
    property :weighting, :type => :integer, :default => 1
    property :assignment_question_group_maps, :default => []

    def hash
      {"id" => id, "assignmentid" => assignmentid, "name" => name, "order_id" => order_id, "weighting" => weighting}
    end

    def map_hashes
      hashes = []
      assignment_question_group_maps.each_with_index do |assignment_question_group_map, index|
        hash = assignment_question_group_map.hash
        hash['order_id'] = index
        hashes.push(hash)
      end
      hashes
    end


    private

  end
end
