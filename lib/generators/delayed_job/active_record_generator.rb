require 'generators/delayed_job/delayed_job_generator'
require 'rails/generators/migration'
require 'rails/generators/active_record/migration'

# Extend the DelayedJobGenerator so that it creates an AR migration
module DelayedJob
  class ActiveRecordGenerator < ::DelayedJobGenerator
    include Rails::Generators::Migration
    extend ActiveRecord::Generators::Migration

    self.source_paths << File.join(File.dirname(__FILE__), 'templates')

    def create_migration_file
      migration_template 'migration.rb', 'db/migrate/create_delayed_jobs.rb'
    end
  end
end
