module Maple
  module MapleTA
    autoload :Assignment, 'mapleta_client/assignment'
    autoload :AssignmentQuestionGroup, 'mapleta_client/assignment_question_group'
    autoload :AssignmentQuestionGroupMap, 'mapleta_client/assignment_question_group_map'
    autoload :Question, 'mapleta_client/question'
    autoload :Communication, 'mapleta_client/communication'
    autoload :Connection, 'mapleta_client/connection'
    autoload :Course, 'mapleta_client/course'
    autoload :HashInitialize, 'mapleta_client/hash_initialize'
    autoload :GradeBook, 'mapleta_client/grade_book'
    autoload :MockConnection, 'mapleta_client/mock_connection'
    autoload :RawString, 'mapleta_client/raw_string'
    autoload :WebService, 'mapleta_client/web_service'
    autoload :HtmlParser, 'mapleta_client/html_parser'

    module Errors
      autoload :DatabaseError, 'mapleta_client/errors/database_error'
      autoload :GradeBookError, 'mapleta_client/errors/grade_book_error'
      autoload :InvalidResponseError, 'mapleta_client/errors/invalid_response_error'
      autoload :MapleTAError, 'mapleta_client/errors/mapleta_error'
      autoload :NetworkError, 'mapleta_client/errors/network_error'
      autoload :NotConnectedError, 'mapleta_client/errors/not_connected_error'
      autoload :NotFoundError, 'mapleta_client/errors/not_found_error'
      autoload :SessionExpiredError, 'mapleta_client/errors/session_expired_error'
      autoload :UnexpectedContentError, 'mapleta_client/errors/unexpected_content_error'
      autoload :TomcatManagerError, 'mapleta_client/errors/tomcat_manager_error'
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
      autoload :MasteryGrade, 'mapleta_client/page/mastery_grade'
      autoload :MasteryQuestion, 'mapleta_client/page/mastery_question'
      autoload :OtherActiveAssignment, 'mapleta_client/page/other_active_assignment'
      autoload :Preview, 'mapleta_client/page/preview'
      autoload :PrintAssignment, 'mapleta_client/page/print_assignment'
      autoload :PrintOrTake, 'mapleta_client/page/print_or_take'
      autoload :ProctorAuthorization, 'mapleta_client/page/proctor_authorization'
      autoload :RestrictedAssignment, 'mapleta_client/page/restricted_assignment'
      autoload :Solution, 'mapleta_client/page/solution'
      autoload :StudyFeedback, 'mapleta_client/page/study_feedback'
      autoload :StudyQuestion, 'mapleta_client/page/study_question'
      autoload :NumberHelp, 'mapleta_client/page/number_help'
      autoload :Question, 'mapleta_client/page/question'
      autoload :TimeLimitExceeded, 'mapleta_client/page/time_limit_exceeded'
      autoload :AnswerParser, 'mapleta_client/page/answer_parser'
    end

    module Database
      autoload :Connection, 'mapleta_client/database/connection'
      autoload :MockConnection, 'mapleta_client/database/mock_connection'
      module Macros
        autoload :Answersheetitem, 'mapleta_client/database/macros/answersheetitem'
        autoload :Assignment, 'mapleta_client/database/macros/assignment'
        autoload :TestRecord, 'mapleta_client/database/macros/test_record'
        autoload :User, 'mapleta_client/database/macros/user'
        autoload :Classes, 'mapleta_client/database/macros/classes'
        autoload :Question, 'mapleta_client/database/macros/question'
      end
    end

    module Orm
      require 'mapleta_client/orm/base'
      autoload :Class, 'mapleta_client/orm/class'
      autoload :Assignment, 'mapleta_client/orm/assignment'
      autoload :AssignmentClass, 'mapleta_client/orm/assignment_class'
      autoload :AssignmentBranch, 'mapleta_client/orm/assignment_branch'
      autoload :AssignmentQuestionGroup, 'mapleta_client/orm/assignment_question_group'
      autoload :AssignmentQuestionGroupMap, 'mapleta_client/orm/assignment_question_group_map'
      autoload :Question, 'mapleta_client/orm/question'
      autoload :QuestionHeader, 'mapleta_client/orm/question_header'
      autoload :AssignmentPolicy, 'mapleta_client/orm/assignment_policy'
      autoload :AssignmentAdvancedPolicy, 'mapleta_client/orm/assignment_advanced_policy'
      autoload :Testrecord, 'mapleta_client/orm/testrecord'
      autoload :Answersheetitem, 'mapleta_client/orm/answersheetitem'
      autoload :UserProfile, 'mapleta_client/orm/user_profile'
    end

    require 'mapleta_client/page'
    require 'mapleta_client/database'
    require 'mapleta_client/tomcat_manager'
  end
end
