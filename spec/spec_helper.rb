$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'mapleta_client'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.add_setting :maple_settings, :default => {
    :base_url        => 'http://localhost:8081/mapleta',
    :secret          => '',
    :first_name      => 'Maple T.A.',
    :middle_name     => nil,
    :last_name       => 'Administrator',
    :user_login      => 'admin',
    :user_email      => 'mapleta@thinkwell.com',
    :user_role       => 'ADMINISTRATOR',
    :student_id      => 'admin',
    :class_id        => 330,
    :class_name      => 'Calculus I',
    :course_id       => 1,

    :assignment_id   => 29928,
    :assignment_name => 'Easy Test',
  }
  Maple::MapleTA.database_config = {
      :host            => 'localhost',
      :dbname          => 'mapleta',
      :user            => 'postgres',
      :password        => '',
      :sslmode         => 'disable',
      :port            => 5432,
      :connect_timeout => 2,
  }
  config.add_setting :maple_values, :default => {
    :assignment_question_number => 1,
    :assignment_question_count => 16,
    :assignment_question_points => 1,
    :assignment_question_text => '(Click For List)',
  }
end


def spec_maple_connection
  Maple::MapleTA::Connection.new(RSpec.configuration.maple_settings)
end
