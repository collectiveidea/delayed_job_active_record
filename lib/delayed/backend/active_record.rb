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
                          :failed_at, :locked_at, :locked_by, :handler, :singleton
        end

        scope :by_priority, lambda { order('priority ASC, run_at ASC') }

        before_save :set_default_run_at
        before_destroy :remove_others_from_singleton_queue

        def remove_others_from_singleton_queue
          if payload_object.respond_to?(:singleton_queue_name)
            self.class.where(:singleton => payload_object.singleton_queue_name).where("id != ?", id).delete_all
          end
        end

        def destroy
          self.class.retry_on_deadlock(10) { super }
        end

        # Override #invoke_job so that there is tagged logging.
        def invoke_job
          if defined?(ActiveSupport::TaggedLogging) && defined?(Rails)
            Rails.logger.tagged(self.name) do
              Rails.logger.info("Entering job")
              super
              Rails.logger.info("Exiting job")
            end
          else
            super
          end
        end

        def self.enqueue(*args)
          options = args.extract_options!
          payload_object = options[:payload_object] || args[0]

          if payload_object.respond_to?(:singleton_queue_name)
            options.merge!(:singleton => payload_object.singleton_queue_name)
          end
          args << options

          super(*args)
        end

        def self.set_delayed_job_table_name
          delayed_job_table_name = "#{::ActiveRecord::Base.table_name_prefix}delayed_jobs"
          self.table_name = delayed_job_table_name
        end

        self.set_delayed_job_table_name

        # Prevent more than one job from a singleton queue from being run at the same time.
        def self.exclude_running_singletons(worker_name, max_run_time)
          sql = [
            "singleton IS NULL",                   # allow it to run if its singleton name is null
            "OR singleton NOT IN (",               # allow it to run if its singleton name is not in the list of currently running singleton job names
              "SELECT *",
              "FROM (",                                             # Use temp-table: MySQL doesn't allow sub-selects from tables locked for update
                "SELECT DISTINCT(singleton) FROM delayed_jobs",     # Prevent us from getting a job from this singleton queue
                "WHERE run_at <= ?",                                # that can be run
                  "AND singleton IS NOT NULL",                      # that is a singleton
                  "AND (locked_at IS NOT NULL AND locked_at >= ?)", # and is currently locked
                  "AND locked_by != ?",                             # by someone other than us
                  "AND failed_at IS NULL",                          # and hasn't failed
              ") AS temp_table",
            ")",
          ].join(" ")

          where(sql, db_time_now, db_time_now - max_run_time, worker_name)
        end

        def self.ready_to_run(worker_name, max_run_time)
          where('(run_at <= ? AND (locked_at IS NULL OR locked_at < ?) OR locked_by = ?) AND failed_at IS NULL', db_time_now, db_time_now - max_run_time, worker_name)
            .exclude_running_singletons(worker_name, max_run_time)
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

        # Our singleton queue subquery is not atomic, and can trigger deadlocks.
        # To cut down on alerting noise, retry several times before giving up and
        # raising an exception.
        def self.retry_on_deadlock(max_retries)
          begin
            yield
          rescue => ex
            # This will always be an ActiveRecord::StatementInvalid, but we can
            # avoid making a new dependency on that class by just checking the message here.
            if ex.message =~ /Deadlock found when trying to get lock/ && max_retries > 0
              max_retries -= 1
              sleep(rand * 0.1)
              retry
            else
              raise ex
            end
          end
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
            retry_on_deadlock(10) do
              count = ready_scope.limit(1).update_all(:locked_at => now, :locked_by => worker.name)
              return nil if count == 0
            end

            self.where(:locked_at => now, :locked_by => worker.name).first
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
