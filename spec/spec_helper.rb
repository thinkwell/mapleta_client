$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'active_support/core_ext/hash'
require 'rspec'
require 'sequel'
require 'vcr'
require 'yaml'
require 'factory_girl'
require 'mapleta_client'


VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/requests'
  c.hook_into :webmock
end

settings = YAML.load_file "#{File.dirname(__FILE__)}/support/settings.yml"


Maple::MapleTA.database_config = settings['database_settings']
DB = Sequel.connect settings['database_settings']

RSpec.configure do |config|
  config.add_setting :maple_values,        default: settings['maple_values']
  config.add_setting :maple_settings,      default: settings['maple_settings']
  config.add_setting :database_connection, default: Maple::MapleTA.database_connection

  config.include FactoryGirl::Syntax::Methods

  config.around :each do |example|
    RSpec.configuration.database_connection.dataset.transaction do
      example.run
      raise Sequel::Rollback
    end
  end
end

FactoryGirl.factories.clear
FactoryGirl.definition_file_paths = %w(spec/fixtures)
FactoryGirl.reload
