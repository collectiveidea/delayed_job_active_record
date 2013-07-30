require 'active_record/version'
module Delayed
  module Backend
    module ActiveRecord
      # A job object that is persisted to the database.
      # Contains the work object as a YAML field.
      class Job < ::ActiveRecord::Base
        include Delayed::Backend::Base

        if ::ActiveRecord::VERSION::MAJOR < 4 || defined?(::ActiveRecord::MassAssignmentSecurity)
          attr_accessible :priority, :run_at, :queue, :payload_object,
                          :failed_at, :locked_at, :locked_by, :handler
        end

        scope :by_priority, lambda { order('priority ASC, run_at ASC') }

        before_save :set_default_run_at

        def self.set_delayed_job_table_name
          delayed_job_table_name = "#{::ActiveRecord::Base.table_name_prefix}delayed_jobs"
          self.table_name = delayed_job_table_name
        end

        self.set_delayed_job_table_name

        def self.ready_to_run(worker_name, max_run_time)
          where('(run_at <= ? AND (locked_at IS NULL OR locked_at < ?) OR locked_by = ?) AND failed_at IS NULL', db_time_now, db_time_now - max_run_time, worker_name)
        end

        def self.before_fork
          ::ActiveRecord::Base.clear_all_connections!
        end

        def self.after_fork
          ::ActiveRecord::Base.establish_connection
        end

        # When a worker is exiting, make sure we don't have any locked jobs.
        def self.clear_locks!(worker_name)
          where(:locked_by => worker_name).update_all(:locked_by => nil, :locked_at => nil)
        end

        def self.reserve(worker, max_run_time = Worker.max_run_time)
          # scope to filter to records that are "ready to run"
          ready_scope = self.ready_to_run(worker.name, max_run_time)

          # scope to filter to the single next eligible job
          ready_scope = ready_scope.where('priority >= ?', Worker.min_priority) if Worker.min_priority
          ready_scope = ready_scope.where('priority <= ?', Worker.max_priority) if Worker.max_priority
          ready_scope = ready_scope.where(:queue => Worker.queues) if Worker.queues.any?
          ready_scope = ready_scope.by_priority

          now = self.db_time_now

          # Optimizations for faster lookups on some common databases
          case self.connection.adapter_name
          when "PostgreSQL"
            # Custom SQL required for PostgreSQL because postgres does not support UPDATE...LIMIT
            # This locks the single record 'FOR UPDATE' in the subquery (http://www.postgresql.org/docs/9.0/static/sql-select.html#SQL-FOR-UPDATE-SHARE)
            # Note: active_record would attempt to generate UPDATE...LIMIT like sql for postgres if we use a .limit() filter, but it would not use
            # 'FOR UPDATE' and we would have many locking conflicts
            quoted_table_name = self.connection.quote_table_name(self.table_name)
            subquery_sql      = ready_scope.limit(1).lock(true).select('id').to_sql
            reserved          = self.find_by_sql(["UPDATE #{quoted_table_name} SET locked_at = ?, locked_by = ? WHERE id IN (#{subquery_sql}) RETURNING *", now, worker.name])
            reserved[0]
          when "MySQL", "Mysql2"
            # This works on MySQL and possibly some other DBs that support UPDATE...LIMIT. It uses separate queries to lock and return the job
            count = ready_scope.limit(1).update_all(:locked_at => now, :locked_by => worker.name)
            return nil if count == 0
            self.where(:locked_at => now, :locked_by => worker.name, :failed_at => nil).first
          when "MSSQL", "Teradata"
            # The MSSQL driver doesn't generate a limit clause when update_all is called directly
            subsubquery_sql = ready_scope.limit(1).to_sql
            # select("id") doesn't generate a subquery, so force a subquery
            subquery_sql = "SELECT id FROM (#{subsubquery_sql}) AS x"
            quoted_table_name = self.connection.quote_table_name(self.table_name)
            sql = ["UPDATE #{quoted_table_name} SET locked_at = ?, locked_by = ? WHERE id IN (#{subquery_sql})", now, worker.name]
            count = self.connection.execute(sanitize_sql(sql))
            return nil if count == 0
            # MSSQL JDBC doesn't support OUTPUT INSERTED.* for returning a result set, so query locked row
            self.where(:locked_at => now, :locked_by => worker.name, :failed_at => nil).first
          else
            # This is our old fashion, tried and true, but slower lookup
            ready_scope.limit(worker.read_ahead).detect do |job|
              count = ready_scope.where(:id => job.id).update_all(:locked_at => now, :locked_by => worker.name)
              count == 1 && job.reload
            end
          end
        end

        # Get the current time (GMT or local depending on DB)
        # Note: This does not ping the DB to get the time, so all your clients
        # must have syncronized clocks.
        def self.db_time_now
          if Time.zone
            Time.zone.now
          elsif ::ActiveRecord::Base.default_timezone == :utc
            Time.now.utc
          else
            Time.now
          end
        end

        def reload(*args)
          reset
          super
        end
      end
    end
  end
end
