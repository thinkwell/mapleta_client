module Maple
  module MapleTA
    autoload :Assignment, 'mapleta/assignment'
    autoload :Communication, 'mapleta/communication'
    autoload :Connection, 'mapleta/connection'
    autoload :Course, 'mapleta/course'
    autoload :HashInitialize, 'mapleta/hash_initialize'
    autoload :RawString, 'mapleta/raw_string'
    autoload :WebService, 'mapleta/web_service'

    module Errors
      autoload :InvalidResponseError, 'mapleta/errors/invalid_response_error'
      autoload :MapleTAError, 'mapleta/errors/mapleta_error'
      autoload :NetworkError, 'mapleta/errors/network_error'
      autoload :NotConnectedError, 'mapleta/errors/not_connected_error'
      autoload :SessionExpiredError, 'mapleta/errors/session_expired_error'
      autoload :UnexpectedContentError, 'mapleta/errors/unexpected_content_error'
    end

    module Page
      autoload :AssignmentQuestion, 'mapleta/page/assignment_question'
      autoload :Base, 'mapleta/page/base'
      autoload :BaseQuestion, 'mapleta/page/base_question'
      autoload :Error, 'mapleta/page/error'
      autoload :Feedback, 'mapleta/page/feedback'
      autoload :Form, 'mapleta/page/form'
      autoload :Grade, 'mapleta/page/grade'
      autoload :OtherActiveAssignment, 'mapleta/page/other_active_assignment'
      autoload :Preview, 'mapleta/page/preview'
      autoload :RestrictedAssignment, 'mapleta/page/restricted_assignment'
      autoload :Solution, 'mapleta/page/solution'
      autoload :StudyFeedback, 'mapleta/page/study_feedback'
      autoload :StudyQuestion, 'mapleta/page/study_question'
      autoload :TimeLimitExceeded, 'mapleta/page/time_limit_exceeded'
    end

    require 'mapleta/page'
  end
end
