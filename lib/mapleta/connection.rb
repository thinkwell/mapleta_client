module Maple::MapleTA
  class Connection
    include Communication
    attr_reader :session, :first_name, :middle_name, :last_name, :user_login, :user_email, :student_id, :user_role, :class_id, :course_id

    def initialize(opts={})
      {
        :class_id => -1,
        :user_role => 'STUDENT',
      }.merge(opts).each do |key, val|
        if self.respond_to?("#{key}=")
          self.send "#{key}=", val
        elsif self.respond_to?("#{key}")
          self.instance_variable_set "@#{key}", val
        end
      end
    end


    def connect
      params = {
        'firstName'  => first_name,
        'middleName' => middle_name,
        'lastName'   => last_name,
        'userLogin'  => user_login,
        'userEmail'  => user_email,
        'studentId'  => student_id,
        'userRole'   => user_role,
        'classId'    => class_id,
      }
      params['courseId'] = course_id if class_id.to_i != -1 && course_id

      data = fetch_api('connect', params)
      @session = data['status']['session'] rescue nil
      @session or raise Errors::MapleTAError, "Cannot start session"
    end


    def disconnect
      if connected?
        fetch_api_response('disconnect')
        @session = nil
      end
    end


    def launcher(action, params={})
      params = launcher_params(action).merge(params)

      fetch_api_page('launcher', params, :post).tap { |page|
        # Add the session cookie to our connection if provided
        agent.cookie_jar.cookies(URI.parse("#{ws_url}/launcher")).each do |cookie|
          @session = cookie.value if cookie.name == 'JSESSIONID'
        end
      }
    end
    alias :launch :launcher






    def connected?
      session != nil
    end


    def ws
      @ws ||= WebService.new(self)
    end


    def launcher_params(action)
      {
        'wsActionID'   => action,
        'wsFirstName'  => first_name,
        'wsMiddleName' => middle_name,
        'wsLastName'   => last_name,
        'wsUserLogin'  => user_login,
        'wsUserEmail'  => user_email,
        'wsStudentId'  => student_id,
        'wsUserRole'   => user_role,
        'wsClassId'    => class_id,
        'wsCourseId'   => course_id,
      }
    end

  end
end
