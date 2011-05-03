require 'mechanize'
require 'logger'

module Maple::MapleTA
  class Assignment
    include HashInitialize
    attr_accessor :classId, :id, :name, :class_name, :mode, :modeDescription, :passingScore, :totalPoints, :weight, :start, :end, :timeLimit, :policy


    def launch(connection, external_data=nil, view_opts={})
      raise Errors::MapleTAError, "Connection class id (#{connection.class_id}) doesn't match assignment class id (#{self.classId})" unless self.classId.to_i == connection.class_id.to_i

      params = {
        'wsExternalData' => external_data,
        'className' => class_name,
        'testName' => name,
        'testId' => id,
      }

      page(connection.launch('assignment', params), connection, view_opts)
    end


    def post(connection, url, data, view_opts={})
      raise Errors::MapleTAError, "Connection class id (#{connection.class_id}) doesn't match assignment class id (#{self.classId})" unless self.classId.to_i == connection.class_id.to_i

      page(connection.fetch_page(url, data, :post), connection, view_opts)
    end


  private

    def page(mechanize_page, connection, view_opts)
      view_opts = {
        :base_url => connection.base_url,
      }.merge(view_opts)

      Maple::MapleTA.Page(mechanize_page, view_opts)
    end

  end
end
