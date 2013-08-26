require 'mechanize'
require 'logger'

module Maple::MapleTA
  class AssignmentQuestionGroupMap
    include HashInitialize
    property :id,                 :type => :integer
    property :groupid,            :type => :integer
    property :name
    property :questionid,         :type => :integer
    property :order_id, :type => :integer, :default => 0
    property :question_uid

    def hash
      {"id" => id, "groupid" => groupid, "questionid" => questionid, "question_uid" => question_uid, "order_id" => order_id}
    end

    private

  end
end
