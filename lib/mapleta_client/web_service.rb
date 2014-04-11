module Maple::MapleTA
  class WebService

    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end


    #
    # API METHODS
    #

    ##
    # Pings the Maple T.A. server.
    #
    # Returns true if ping was successful, false otherwise
    #
    def ping
      begin
        response = fetch('ping', {
          'value' => 'foobar',
        })
      rescue Errors::NetworkError, Errors::InvalidResponseError
        return false
      end

      response['value'] == 'foobar' rescue false
    end


    # Retrieves a list of Maple T.A. classes meeting specified criteria
    # Must be connected via #connect
    #
    # Returns array of Course objects
    #
    def classes(featured_only=false, open_for_registration=false)
      raise Errors::NotConnectedError unless connected?

      response = fetch('class', {
        'classId' => 0,
        'featured' => !!featured_only,
        'openForRegistration' => !!open_for_registration,
      })

      hydrate('course', response)
    end

    # Retrieves a Maple T.A. class for given cid
    # Must be connected via #connect
    #
    # Returns a Course object or null if no class exists
    #
    def clazz(cid, featured_only=false, open_for_registration=false)
      raise Errors::NotConnectedError unless connected?

      response = fetch('class', {
        'classId' => cid,
        'featured' => !!featured_only,
        'openForRegistration' => !!open_for_registration,
      })

      hydrate('course', response)
    end


    ##
    # Creates new Maple T.A. class
    # Must be connected via #connect
    #
    # Returns Course object representing the class that was created
    #
    def create_class(course_name, course_id=nil, parent_id=0)
      raise Errors::NotConnectedError unless connected?

      params = {
        'parentClassId' => parent_id,
        'classId' => 0,
      }
      params['courseName'] = course_name if course_name
      params['courseId'] = course_id if course_id

      hydrate('course', fetch('createclass', params))
    end


    ##
    # Updates the course id for an existing class
    # Must be connected via #connect
    #
    # Returns Course object representing the class that was updated
    #
    def update_class(class_id, course_id)
      raise Errors::NotConnectedError unless connected?

      params = {
        'parentClassId' => 0,
        'classId' => class_id,
        'courseId' => course_id,
      }

      hydrate('course', fetch('createclass', params))
    end


    ##
    # Retrieves a single assignment given its id
    # Must be connected to a class via #connect
    #
    # Params:
    #   assignment_id
    #   class_id (optional)
    # - or -
    #   assignment (Assignment object)
    #
    # Returns an Assignment object
    #
    def assignment(*args)
      raise Errors::NotConnectedError unless connected?
      if args[0].is_a?(Assignment)
        assignment_id = args[0].id
        class_id = args[0].class_id
        assignment = args[0]
      else
        assignment_id = args[0]
        class_id = args[1]
        assignment = :assignment
      end

      response = fetch('assignment', {
        'classId' => class_id || connection.class_id,
        'assignmentId' => assignment_id,
      })

      hydrate(assignment, response)
    end


    ##
    # Retrieves a list of assignments for the given class
    # Must be connected to a class via #connect
    #
    # Returns an array of Assignment objects
    #
    def assignments(class_id=nil)
      result = assignment(0, class_id)
      result = [result].compact unless result.is_a?(Array)
      result
    end


    ##
    # Retrieves a list of grades
    # Must be connected to a class via #connect
    #
    # score_type is one of:
    #   * 0   - best
    #   * 1   - average
    #   * 2   - last
    #   * nil - Maple T.A. default
    def grades(class_id=nil, assignment_ids=[], score_type=nil, user_filter=nil)
      raise Errors::NotConnectedError unless connected?

      params = {
        'classId' => class_id || connection.class_id,
      }
      params['userFilter'] = user_filter if user_filter
      params['scoreType'] = score_type if score_type
      if assignment_ids && !assignment_ids.empty?
        params['assignment_ids'] = assignment_ids
      end

      response = fetch('grade', params)

      # TODO: Parse response and hydrate object!
    end


  protected

    def fetch(method, params={})
      parse_data connection.fetch_api(method, params)
    end


    def parse_data(data)
      if data['status'] && data['status']['code'].to_i == 100
        nil
      elsif data['list']
        data['list']['element']
      elsif data['element']
        data['element']
      else
        nil
      end
    end


    def hydrate(type, data)

      if type.is_a?(HashInitialize)
        raise Errors::NotFoundError if data.nil?
        type.hydrate(data)
      else

        klass = "Maple::MapleTA::#{type.to_s.camelize}".constantize

        if data.is_a?(Array)
          data.map { |hash| klass.new underscore_hash_keys(hash) }
        elsif data.is_a?(Hash)
          klass.new underscore_hash_keys(data)
        else
          nil
        end

      end
    end

    def underscore_hash_keys(hash)
      hash.keys.each { |key| hash[key.to_s.underscore] = hash.delete(key) }
      hash
    end

    private
    def connected?
      connection.connected?
    end
  end
end
