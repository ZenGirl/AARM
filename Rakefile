#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'active_record'

require 'rack/aarm/configuration'

RSpec::Core::RakeTask.new('spec')

task :default => :spec

RUN_ENV = 'test' unless defined?(RUN_ENV)

namespace :db do

  task :logger do
    @logger = Rack::AARM::Configuration.logger
    @logger.info "Rake: START"
  end

  task :current_env => :logger do
    DATABASE_ENV = ENV['DATABASE_ENV'] || 'development'
    MIGRATIONS_DIR = ENV['MIGRATIONS_DIR'] || 'db/migrate'
    @logger.info "DATABASE_ENV: #{DATABASE_ENV}"
    @logger.info "MIGRATIONS_DIR: #{MIGRATIONS_DIR}"
  end

  task :configuration => :current_env do
    @config = YAML.load_file('config/database.yml')[DATABASE_ENV]
    @logger.info "db config: #{@config}"
  end

  task :configure_connection => :configuration do
    ActiveRecord::Base.establish_connection @config
    ActiveRecord::Base.logger = @logger #Logger.new STDOUT if @config['logger']
  end

  desc 'Migrate the database (options: VERSION=x, VERBOSE=false).'
  task :migrate => :configure_connection do
    @logger.info "Migrations: START"
    @logger.info Dir[MIGRATIONS_DIR]
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate MIGRATIONS_DIR, ENV['VERSION'] ? ENV['VERSION'].to_i : nil
    @logger.info "Migrations: END"
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback => :configure_connection do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveRecord::Migrator.rollback MIGRATIONS_DIR, step
  end

  desc "Retrieves the current schema version number"
  task :version => :configure_connection do
    puts "Current version: #{ActiveRecord::Migrator.current_version}"
  end

  #
  #desc "Migrate the database"
  #task(:migrate => RUN_ENV) do
  #  logger = Rack::AARM::Configuration.logger
  #  logger.info "Rake: --- Migration START --"
  #  database_yml = File.join(__dir__, 'config', 'database.yml')
  #  logger.info "Rake: loading from #{database_yml}"
  #  default_conf = YAML::load_file(database_yml)
  #  logger.info "Rake: config [#{default_conf[RUN_ENV]}]"
  #  ActiveRecord::Base.establish_connection(default_conf[RUN_ENV])
  #  ActiveRecord::Base.logger = logger
  #  ActiveRecord::Migration.verbose = true
  #  ActiveRecord::Migrator.migrate("db/migrate")
  #end
end
