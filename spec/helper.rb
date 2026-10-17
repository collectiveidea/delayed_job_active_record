# frozen_string_literal: true

require "simplecov"
require "simplecov-lcov"

SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.single_report_path = "coverage/lcov.info"
end
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::LcovFormatter
]

SimpleCov.start do
  skip "/spec/"
end

require "logger"
require "rspec"

begin
  require "protected_attributes"
rescue LoadError # rubocop:disable Lint/SuppressedException
end
require "delayed_job_active_record"
require "delayed/backend/shared_spec"

Delayed::Worker.logger = Logger.new("/tmp/dj.log")
ENV["RAILS_ENV"] = "test"

db_adapter = ENV.fetch("ADAPTER", nil)
gemfile = ENV.fetch("BUNDLE_GEMFILE", nil)
db_adapter ||= gemfile && gemfile[%r{gemfiles/(.*?)/}] && $1 # rubocop:disable Style/PerlBackrefs
db_adapter ||= "sqlite3"

if db_adapter == "trilogy" && Gem::Version.new("7.1") > Gem::Version.new(ActiveRecord::VERSION::STRING)
  require "trilogy_adapter/connection"
  ActiveSupport.on_load(:active_record) { extend TrilogyAdapter::Connection }
end

config = YAML.load_file("spec/database.yml")
ActiveRecord::Base.establish_connection config[db_adapter]
ActiveRecord::Base.logger = Delayed::Worker.logger
ActiveRecord::Migration.verbose = false

migration_template = File.open("lib/generators/delayed_job/templates/migration.rb")

# need to eval the template with the migration_version intact
migration_context =
  Class.new do
    def my_binding
      binding
    end

    private

    def migration_version
      "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
    end
  end

migration_ruby = ERB.new(migration_template.read).result(migration_context.new.my_binding)
eval(migration_ruby) # rubocop:disable Security/Eval

ActiveRecord::Schema.define do
  drop_table :delayed_jobs, if_exists: true

  CreateDelayedJobs.up

  create_table :stories, primary_key: :story_id, force: true do |table|
    table.string :text
    table.boolean :scoped, default: true
  end
end

# Purely useful for test cases...
class Story < ActiveRecord::Base
  self.primary_key = :story_id

  def tell
    text
  end

  def whatever(number)
    tell * number
  end
  default_scope { where(scoped: true) }

  handle_asynchronously :whatever
end

# Add this directory so the ActiveSupport autoloading works
ActiveSupport::Dependencies.autoload_paths << File.dirname(__FILE__)
