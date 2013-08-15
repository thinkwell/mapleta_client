require 'mechanize'
require 'logger'

module Maple::MapleTA
  class Question
    include HashInitialize
    property :id,                 :type => :integer
    property :name
    property :uid
    property :order_id, :type => :integer, :default => 0
    property :weighting, :type => :integer, :default => 1
    property :author, :type => :integer, :default => 0

  private

  end
end
