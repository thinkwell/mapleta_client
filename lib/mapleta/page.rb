module Maple::MapleTA

  # Create a new Maple Page given a Mechanize object
  def self.Page(page, opts={})
    Maple::MapleTA::Page.for(page, opts)
  end

  module Page

    def self.classes
      [AssignmentQuestion, StudyQuestion, Grade, RestrictedAssignment, TimeLimitExceeded, OtherActiveAssignment, PrintOrTake, Error]
    end

    def self.for(page, opts={})
      klass = classes.detect { |c| c.detect(page) }
      raise Errors::UnexpectedContentError.new(page.parser, "Cannot detect page type") unless klass

      klass.new(page, opts)
    end

  end
end
