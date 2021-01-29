# frozen_string_literal: true

require "simplecov"
require "simplecov-lcov"

SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.single_report_path = "coverage/lcov.info"
end
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ]
)

SimpleCov.start do
  add_filter "/spec/"
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

db_adapter = ENV["ADAPTER"]
gemfile = ENV["BUNDLE_GEMFILE"]
db_adapter ||= gemfile && gemfile[%r{gemfiles/(.*?)/}] && $1 # rubocop:disable Style/PerlBackrefs
db_adapter ||= "sqlite3"

config = YAML.load(File.read("spec/database.yml"))
ActiveRecord::Base.establish_connection config[db_adapter]
ActiveRecord::Base.logger = Delayed::Worker.logger
ActiveRecord::Migration.verbose = false

# MySQL 5.7 no longer supports null default values for the primary key
# Override the default primary key type in Rails <= 4.0
# https://stackoverflow.com/a/34555109
if db_adapter == "mysql2"
  types = if defined?(ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter)
    # ActiveRecord 3.2+
    ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::NATIVE_DATABASE_TYPES
  else
    # ActiveRecord < 3.2
    ActiveRecord::ConnectionAdapters::Mysql2Adapter::NATIVE_DATABASE_TYPES
  end
  types[:primary_key] = types[:primary_key].sub(" DEFAULT NULL", "")
end

migration_template = File.open("lib/generators/delayed_job/templates/migration.rb")

# need to eval the template with the migration_version intact
migration_context =
  Class.new do
    def my_binding
      binding
    end

    private

    def migration_version
      "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]" if ActiveRecord::VERSION::MAJOR >= 5
    end
  end

migration_ruby = ERB.new(migration_template.read).result(migration_context.new.my_binding)
eval(migration_ruby) # rubocop:disable Security/Eval

ActiveRecord::Schema.define do
  if table_exists?(:delayed_jobs)
    # `if_exists: true` was only added in Rails 5
    drop_table :delayed_jobs
  end

  CreateDelayedJobs.up

  create_table :stories, primary_key: :story_id, force: true do |table|
    table.string :text
    table.boolean :scoped, default: true
  end
end

# Purely useful for test cases...
class Story < ActiveRecord::Base
  if ::ActiveRecord::VERSION::MAJOR < 4 && ActiveRecord::VERSION::MINOR < 2
    set_primary_key :story_id
  else
    self.primary_key = :story_id
  end
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
