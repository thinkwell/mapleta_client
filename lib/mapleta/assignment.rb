require 'mechanize'
require 'logger'

module Maple::MapleTA
  class Assignment
    include HashInitialize
    property :class_id,         :type => :integer,      :from => :classId
    property :id,               :type => :integer
    property :class_name
    property :name, :default => nil
    property :mode, :type => :integer, :default => nil
    property :mode_description, :from => :modeDescription, :default => nil
    property :passing_score, :type => :integer, :from => :passingScore, :default => nil
    property :total_points, :type => :float, :from => :totalPoints, :default => nil
    property :weight, :type => :float, :default => nil
    property :start, :type => :time_from_ms, :default => nil
    property :end, :type => :time_from_ms, :default => nil
    property :time_limit, :type => :integer, :from => :timeLimit, :default => nil
    property :policy, :default => nil

    MODE_PROCTERED_TEST     = 0
    MODE_UNPROCTERED_TEST   = 1
    MODE_PRACTICE           = 2
    MODE_MASTERY_ASSIGNMENT = 3
    MODE_STUDY_SESSION      = 4


    def load(connection)
      defaults!
      connection.ws.assignment(self)
    end
    alias :reload :load


    def launch(connection, external_data=nil, view_opts={})
      raise Errors::MapleTAError, "Connection class id (#{connection.class_id}) doesn't match assignment class id (#{self.class_id})" unless self.class_id == connection.class_id.to_i

      params = {
        'wsExternalData' => external_data,
        'className' => class_name,
        'testName' => name,
        'testId' => id,
      }

      page(connection.launch('assignment', params), connection, view_opts)
    end


    def post(connection, url, data, view_opts={})
      raise Errors::MapleTAError, "Connection class id (#{connection.class_id}) doesn't match assignment class id (#{self.class_id})" unless self.class_id == connection.class_id.to_i

      page(connection.fetch_page(url, data, :post), connection, view_opts)
    end


    def timed?
      time_limit > 0 && ![MODE_PRACTICE, MODE_STUDY_SESSION].include?(mode)
    end


    def recorded?
      [MODE_PROCTERED_TEST, MODE_UNPROCTERED_TEST, MODE_MASTERY_ASSIGNMENT].include?(mode)
    end



  private

    def page(mechanize_page, connection, view_opts)
      Maple::MapleTA.Page(mechanize_page, view_opts)
    end

  end
end
