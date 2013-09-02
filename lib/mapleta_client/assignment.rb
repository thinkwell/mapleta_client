require 'mechanize'
require 'logger'

module Maple::MapleTA
  class Assignment
    include HashInitialize
    property :class_id,           :type => :integer,      :from => :classId
    property :id,                 :type => :integer
    property :reuse_algorithmic_variables, :type => :boolean, :default => false
    property :targeted, :type => :boolean, :default => false
    property :visible, :type => :boolean, :default => true
    property :final_grade, :type => :boolean, :default => true
    property :create_assignment, :type => :boolean, :default => false
    property :show_current_grade, :type => :boolean, :default => false
    property :insession_grade,    :type => :boolean, :default => false
    property :reworkable,         :type => :boolean, :default => true
    property :printable,         :type => :boolean,  :default => false
    property :final_feedback_date, :type => :date, :default => nil
    property :allow_resubmit_question, :type => :boolean, :default => true
    property :max_attempts,         :type => :integer_nilable, :default => nil
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
    property :time_limit, :type => :integer_nilable, :from => :timeLimit, :default => nil
    property :policy, :default => nil
    property :assignment_question_groups, :default => []

    MODE_PROCTORED_TEST     = 0
    MODE_UNPROCTORED_TEST   = 1
    MODE_PRACTICE           = 2
    MODE_MASTERY_ASSIGNMENT = 3
    MODE_STUDY_SESSION      = 4

    SCRAMBLE_NEVER = 0
    SCRAMBLE_FIRST = 1
    SCRAMBLE_EVERY = 2

    def self.scramble_options
      [["Never", SCRAMBLE_NEVER], ["On the first attempt", SCRAMBLE_FIRST], ["Every attempt", SCRAMBLE_EVERY]]
    end

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

    def classid=(classid)
      self.class_id = classid
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

    def assignment_hash
      {"id" => nil, "classid" => class_id, "name" => name, "totalpoints" => total_points, "weighting" => weighting}
    end

    def assignment_class_hash
      {"id" => id, "assignmentid" => nil, "classid" => class_id, "name" => name, "totalpoints" => total_points,
       "order_id" => 0, "weighting" => weighting}
    end

    def assignment_policy_hash
      final_feedback_date = self.final_feedback_date.blank? ? nil : self.final_feedback_date
      hash = {"assignment_class_id" => nil, "show_current_grade" => show_current_grade, "insession_grade" => insession_grade, "reworkable" => reworkable,
      "mode" => (mode.nil? ? 0 : mode), "show_final_grade_feedback" => show_final_grade_feedback, "final_grade" => final_grade,
      "visible" => visible, "time_limit" => (time_limit.nil? ? -1 : time_limit), "final_feedback_date" => final_feedback_date, "final_feedback_delayed" => !final_feedback_date.nil?,
      "allow_resubmit_question" => allow_resubmit_question}
      if hash["mode"] == MODE_UNPROCTORED_TEST
        hash.merge!({"scramble" => scramble, "printable" => printable,
                    "reuse_algorithmic_variables" => reuse_algorithmic_variables, "targeted" => targeted})
      elsif hash["mode"] == MODE_PROCTORED_TEST
        hash.merge!({"start_authorization_required" => "true"})
      end
      hash
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
      unless max_attempts.nil?
        hashes.push({"assignment_class_id" => id, "assignment_id" => nil , "and_id" => 0, "or_id" => 0, "keyword" => max_attempts, "has" => false})
      end
      hashes
    end

  private

    def page(mechanize_page, connection, view_opts)
      Maple::MapleTA.Page(mechanize_page, view_opts)
    end

  end
end
