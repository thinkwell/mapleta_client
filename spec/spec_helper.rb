$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'mapleta'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.add_setting :maple_settings, :default => {
    :base_url        => 'http://localhost:8080/mapleta',
    :secret          => 'Mk0W1b4Cwa-m',
    :first_name      => 'Brandon',
    :middle_name     => nil,
    :last_name       => 'Turner',
    :user_login      => 'brandont@thinkwell.com',
    :user_email      => 'brandont@thinkwell.com',
    :student_id      => 1,
    :class_id        => 2,
    :class_name      => 'Calculus I',
    :course_id       => 1,

    :assignment_id   => 3,
    :assignment_name => 'Easy Test',
  }
  config.add_setting :maple_values, :default => {
    :assignment_question_number => 1,
    :assignment_question_count => 2,
    :assignment_question_points => 40,
    :assignment_question_text => 'What is 2+2?',
  }
end


def spec_maple_connection
  Maple::MapleTA::Connection.new(RSpec.configuration.maple_settings)
end
