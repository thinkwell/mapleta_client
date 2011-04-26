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
      autoload :UnexpectedContentError, 'mapleta/errors/unexpected_content_error'
    end

    module Page
      autoload :Base, 'mapleta/page/base'
      autoload :Feedback, 'mapleta/page/feedback'
      autoload :Form, 'mapleta/page/form'
      autoload :Grade, 'mapleta/page/grade'
      autoload :Preview, 'mapleta/page/preview'
      autoload :Question, 'mapleta/page/question'
      autoload :RestrictedAssignment, 'mapleta/page/restricted_assignment'
    end

    require 'mapleta/page'
  end
end
