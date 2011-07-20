module Maple::MapleTA
  class GradeBook

    attr_reader :connection
    attr_accessor :from, :to, :assignment_ids, :user_id


    #
    # Create a gradebook object
    #
    # NOTE: The connection must be an administrator connection
    #
    def initialize(connection, opts={})
      @connection = connection
      opts.each do |key, val|
        self.send("#{key}=", val) if self.respond_to?("#{key}=")
      end
    end



    def assignment_ids
      @assignment_ids ||= assignments.map { |a| a.id }
    end


    def assignment_ids=(ids)
      @assignment_ids = (ids.is_a?(Array) ? ids : [ids]).compact
    end


    def user_id=(id)
      @user_id = id
    end




    def grades
      fetch_grades unless loaded?
      flatten @grades
    end


    def assignment_grades(assignment_ids)
      grades_for(assignment_ids, nil)
    end


    def user_grades(user_id)
      grades_for(nil, user_id)
    end


    def grades_for(assignment_ids=nil, user_id=nil)
      unless loaded?
        # TODO: Should we prefetch everything?
        self.assignment_ids = assignment_ids
        self.user_id = user_id
        return grades
      end

      filter = []

      assignment_ids = [assignment_ids] if assignment_ids && !assignment_ids.is_a?(Array)

      @grades.each do |assignment_id, users|
        if assignment_ids.nil? || assignment_ids.include?(assignment_id)
          users.each do |uid, attempts|
            if user_id.nil? || user_id == uid
              filter << attempts
            end
          end
        end
      end

      filter
    end


    def fetch_grades
      connect unless connected?

      params = {
        'actionID'            => 0,
        'assignmentId'        => 0,
        'trId'                => 0,
        'classSelection'      => connection.class_id,
        'userId'              => nil,
        'assignmentSelection' => assignment_ids,
        'uid'                 => user_id,
        'userList'            => 0,
        'resultType'          => 5, # All (most recent)
        'numberOfRows'        => 1000,
        'active'              => 1,
        'gradingStyle'        => 0,
        'dateRangeStart'      => self.from.to_i * 1000 || 0,
        'dateRangeEnd'        => self.to.to_i * 1000 || 0,
        'quGroup'             => -1,
        'quRef'               => -1,
        'showStudents'        => 'on',
        'showInstructors'     => 'on',
        'showProctors'        => 'on',
        'showUid'             => 'on',
        'showAsgnTotalPoints' => 'on',
        'showStartDate'       => 'on',
        'showStartTime'       => 'on',
        'showEndDate'         => 'on',
        'showEndTime'         => 'on',
      }

      page = Page::GradeBook.new(connection.fetch_page('gradebook/Class.do', params, :post))
      parse_page(page)
    end


    def assignments
      @assignments ||= connection.ws.assignments.select { |a| a.recorded? }
    end


    def loaded?
      !!@grades
    end


    def unload!
      @grades = nil
    end


    def reset
      @grades = nil
      @from = nil
      @to = nil
      @assignment_ids = nil
      @user_id = nil
    end


  protected

    def parse_page(page)
      @grades = {} unless @grades
      fetched = 0
      page.grade_table.each do |assignment_id, users|
        @grades[assignment_id] = {} unless @grades[assignment_id]
        users.each do |user_id, attempts|
          @grades[assignment_id][user_id] = attempts.map do |attempt|
            fetched += 1
            obj = attempt.dup
            obj['assignmentId'] = assignment_id
            obj['userLogin'] = user_id
            obj['score'] = obj.delete('Grade') if obj['Grade']
            obj['dateStarted'] = obj.delete('Start') if obj['Start']
            obj['dateGraded'] = obj.delete('End') if obj['End']
            obj
          end
        end
      end

      fetched
    end


    def flatten(grades)
      return [] if grades.nil?
      return grades if grades.is_a?(Array)

      new_grades = []
      grades.each do |key, val|
        if val.is_a?(Array)
          new_grades += val
        elsif val.is_a?(Hash)
          val.each do |key2, val2|
            new_grades += val2 if val2.is_a?(Array)
          end
        end
      end

      new_grades
    end



  private

    delegate :connect, :connected?, :to => :connection

  end
end
