require 'mechanize'
require 'logger'

module Maple::MapleTA
  class Assignment
    include HashInitialize
    property :class_id,           :type => :integer,      :from => :classId
    property :id,                 :type => :integer
    property :visible, :type => :boolean, :default => true
    property :final_grade, :type => :boolean, :default => true
    property :show_current_grade, :type => :boolean, :default => false
    property :insession_grade,    :type => :boolean, :default => false
    property :reworkable,         :type => :boolean, :default => true
    property :printable,         :type => :boolean,  :default => false
    property :weighting,         :type => :integer, :default => 0
    property :scramble,         :type => :integer, :default => 0
    property :show_final_grade_feedback, :default => ''
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
    property :questions, :default => []

    MODE_PROCTORED_TEST     = 0
    MODE_UNPROCTORED_TEST   = 1
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
      time_limit > 0 && self.class.timeable?(mode)
    end

    def self.timeable?(mode)
      ![MODE_PRACTICE, MODE_STUDY_SESSION].include?(mode)
    end

    def recorded?
      self.class.recorded?(mode)
    end

    def self.recorded?(mode)
      [MODE_PROCTORED_TEST, MODE_UNPROCTORED_TEST, MODE_MASTERY_ASSIGNMENT].include?(mode)
    end

    def proctored?
      self.class.proctored?(mode)
    end

    def self.proctored?(mode)
      mode == MODE_PROCTORED_TEST
    end

    def unproctored?
      self.class.unproctored?(mode)
    end

    def self.unproctored?(mode)
      mode == MODE_UNPROCTORED_TEST
    end

    def practice?
      self.class.practice?(mode)
    end

    def self.practice?(mode)
      mode == MODE_PRACTICE
    end

    def mastery?
      self.class.mastery?(mode)
    end

    def self.mastery?(mode)
      mode == MODE_MASTERY_ASSIGNMENT
    end

    def study_session?
      self.class.study_session?(mode)
    end

    def self.study_session?(mode)
      mode == MODE_STUDY_SESSION
    end

    def include_questionid?(questionid)
      questions.map{|question| question.id}.include?(questionid)
    end

    def assignment_hash
      {"id" => id, "classid" => class_id, "name" => name, "totalpoints" => total_points, "weighting" => weighting}
    end

    def assignment_class_hash
      {"id" => nil, "assignmentid" => id, "classid" => class_id, "name" => name, "totalpoints" => total_points,
       "order_id" => 0, "weighting" => weighting}
    end

    def assignment_policy_hash
      {"assignment_class_id" => nil, "show_current_grade" => show_current_grade, "insession_grade" => insession_grade, "reworkable" => reworkable,
      "printable" => printable, "mode" => (mode.nil? ? 0 : mode), "show_final_grade_feedback" => show_final_grade_feedback, "final_grade" => final_grade,
      "visible" => visible, "scramble" => scramble}
    end

    def assignment_question_group_hashes(questions=nil)
      hashes = []
      q = questions
      unless questions
        q = self.questions
      end
      q.each_with_index {|question,i| hashes.push({"id" => nil, "assignmentid" => nil, "name" => question.name, "order_id" => i, "weighting" => question.weighting})}
      hashes
    end

    def assignment_question_group_map_hashes(questions=nil)
      hashes = []
      q = questions
      unless questions
        q = self.questions
      end
      q.each {|question| hashes.push({"groupid" => nil, "questionid" => question.id, "question_uid" => question.uid})}
      hashes
    end

    def assignment_mastery_policy_hashes
      hashes = []
      hashes
    end

    def assignment_mastery_penalty_hashes
      hashes = []
      hashes
    end

    def assignment_advanced_policy_hashes
      hashes = []
      hashes
    end

  private

    def page(mechanize_page, connection, view_opts)
      Maple::MapleTA.Page(mechanize_page, view_opts)
    end

  end
end
