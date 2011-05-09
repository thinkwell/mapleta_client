module Maple::MapleTA
  module Errors
    class SessionExpiredError < MapleTAError

      attr_reader :session

      def initialize(session, msg=nil)
        @session = session
        super(msg || "Your maple session has expired")
      end

    end
  end
end
