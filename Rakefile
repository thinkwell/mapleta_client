require 'bundler/gem_tasks'
require 'yaml'

task :environment do |cmd, args|
  require 'bundler/setup'
  require 'sequel'

  config = YAML.load_file("#{File.dirname(__FILE__)}/spec/support/settings.yml")
  DB     = Sequel.connect config['database_settings']
  ENV["RACK_ENV"] = args[:env] || "development"
end

namespace :db do
  desc "Create the db defined in support/config.yml"

  desc "Run database migrations"
  task :migrate do |cmd, args|
    Rake::Task['environment'].invoke

    require 'sequel/extensions/migration'
    load "#{File.dirname(__FILE__)}/spec/support/schema.rb"

    Sequel::Migration.descendants.each { |m| m.apply(DB, :up) }
  end
end
