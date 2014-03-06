$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'vcr'
require 'yaml'
require 'mapleta_client'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/requests'
  c.hook_into :webmock
end

settings = YAML.load_file("#{File.dirname(__FILE__)}/support/settings.yml")

Maple::MapleTA.database_config = settings['database_settings']

RSpec.configure do |config|
  config.add_setting :maple_values, default: settings['maple_values']
  config.add_setting :maple_settings, default: settings['maple_settings']
  config.add_setting :database_connection, default: Maple::MapleTA.database_connection

  config.around :each do |example|
    catch :rollback do

      RSpec.configuration.database_connection.transaction do
        example.run
        throw :rollback
      end

    end
  end
end
