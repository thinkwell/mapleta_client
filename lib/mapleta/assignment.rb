require 'mechanize'
require 'logger'

module Maple::MapleTA
  class Assignment
    include HashInitialize
    attr_accessor :classId, :id, :name, :class_name, :mode, :modeDescription, :passingScore, :totalPoints, :weight, :start, :end, :timeLimit, :policy


    def launch(connection, external_data=nil, view_opts={})
      raise Errors::MapleTAError, "Connection class id doesn't match assignment class id" unless self.classId == connection.class_id

      params = {
        'wsExternalData' => external_data,
        'className' => class_name,
        'testName' => name,
        'testId' => id,
      }

      question_view(connection.launch('assignment', params), connection, view_opts)
    end


    def post(connection, url, data, view_opts={})
      raise Errors::MapleTAError, "Connection class id doesn't match assignment class id" unless self.classId == connection.class_id

      question_view(connection.fetch_page(url, data, :post), connection, view_opts)
    end


  private

    def question_view(page, connection, view_opts)
      view_opts = {
        :base_url => connection.base_url,
      }.merge(view_opts)

      QuestionView.new(page, view_opts)
    end

  end
end
