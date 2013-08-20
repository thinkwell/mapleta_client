module Maple::MapleTA

  # Create a new Maple Page given a Mechanize object
  def self.Page(page, opts={})
    Maple::MapleTA::Page.for(page, opts)
  end

  module Page

    def self.classes
      [AssignmentQuestion, StudyQuestion, MasteryQuestion, Grade, MasteryGrade, RestrictedAssignment, TimeLimitExceeded, OtherActiveAssignment, ProctorAuthorization, PrintOrTake, PrintAssignment, Error, NumberHelp, Question]
    end

    def self.for(page, opts={})
      klass = classes.detect { |c| c.detect(page) }
      puts "mapleta : page : #{page.parser}"
      raise Errors::UnexpectedContentError.new(page.parser, "Cannot detect page type") unless klass
      puts "mapleta : detected page : #{klass}"
      klass.new(page, opts)
    end

    def self.default_options
      @default_options
    end

    def self.default_options=(opts)
      @default_options = opts
    end
  end
end
