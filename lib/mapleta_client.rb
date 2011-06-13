module Maple
  module MapleTA
    autoload :Assignment, 'mapleta_client/assignment'
    autoload :Communication, 'mapleta_client/communication'
    autoload :Connection, 'mapleta_client/connection'
    autoload :Course, 'mapleta_client/course'
    autoload :HashInitialize, 'mapleta_client/hash_initialize'
    autoload :GradeBook, 'mapleta_client/grade_book'
    autoload :RawString, 'mapleta_client/raw_string'
    autoload :WebService, 'mapleta_client/web_service'

    module Errors
      autoload :GradeBookError, 'mapleta_client/errors/grade_book_error'
      autoload :InvalidResponseError, 'mapleta_client/errors/invalid_response_error'
      autoload :MapleTAError, 'mapleta_client/errors/mapleta_error'
      autoload :NetworkError, 'mapleta_client/errors/network_error'
      autoload :NotConnectedError, 'mapleta_client/errors/not_connected_error'
      autoload :NotFoundError, 'mapleta_client/errors/not_found_error'
      autoload :SessionExpiredError, 'mapleta_client/errors/session_expired_error'
      autoload :UnexpectedContentError, 'mapleta_client/errors/unexpected_content_error'
    end

    module Page
      autoload :AssignmentQuestion, 'mapleta_client/page/assignment_question'
      autoload :Base, 'mapleta_client/page/base'
      autoload :BaseQuestion, 'mapleta_client/page/base_question'
      autoload :Error, 'mapleta_client/page/error'
      autoload :Feedback, 'mapleta_client/page/feedback'
      autoload :Form, 'mapleta_client/page/form'
      autoload :Grade, 'mapleta_client/page/grade'
      autoload :GradeBook, 'mapleta_client/page/grade_book'
      autoload :GradeReport, 'mapleta_client/page/grade_report'
      autoload :OtherActiveAssignment, 'mapleta_client/page/other_active_assignment'
      autoload :Preview, 'mapleta_client/page/preview'
      autoload :PrintAssignment, 'mapleta_client/page/print_assignment'
      autoload :PrintOrTake, 'mapleta_client/page/print_or_take'
      autoload :RestrictedAssignment, 'mapleta_client/page/restricted_assignment'
      autoload :Solution, 'mapleta_client/page/solution'
      autoload :StudyFeedback, 'mapleta_client/page/study_feedback'
      autoload :StudyQuestion, 'mapleta_client/page/study_question'
      autoload :TimeLimitExceeded, 'mapleta_client/page/time_limit_exceeded'
    end

    require 'mapleta_client/page'
  end
end
