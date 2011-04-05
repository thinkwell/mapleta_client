module Maple
  module MapleTA
    autoload :Assignment, 'mapleta/assignment'
    autoload :Communication, 'mapleta/communication'
    autoload :Connection, 'mapleta/connection'
    autoload :Course, 'mapleta/course'
    autoload :HashInitialize, 'mapleta/hash_initialize'
    autoload :QuestionView, 'mapleta/question_view'
    autoload :WebService, 'mapleta/web_service'

    module Errors
      autoload :InvalidResponseError, 'mapleta/errors/invalid_response_error'
      autoload :MapleTAError, 'mapleta/errors/mapleta_error'
      autoload :NetworkError, 'mapleta/errors/network_error'
      autoload :NotConnectedError, 'mapleta/errors/not_connected_error'
      autoload :UnexpectedContentError, 'mapleta/errors/unexpected_content_error'
    end
  end
end
