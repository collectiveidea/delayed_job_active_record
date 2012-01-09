require 'active_record'
require 'active_record/version'

module ActiveRecord
  class Base
    
    # From lib/active_record/base.rb
    # grep @ lib/active_record/base.rb | sed "s/^[ \t]*//" | egrep -v @@ | sort -u
    RAILS2_IVARS = [:@abstract_class, :@attribute, :@attributes, :@attributes_cache, :@changed_attributes, :@column_names, :@columns, :@columns_hash, :@content_columns, :@destroyed, :@dynamic_methods_hash, :@errors, :@exception, :@finder_needs_type_condition, :@generated_methods, :@inheritance_column, :@message, :@new_record, :@new_record_before_save, :@readonly]
    
    # From lib/active_record/base.rb (union of Rails 3.0 and Rails 3.1)
    # grep @ lib/active_record/base.rb | sed "s/^[ \t]*//" | egrep -v @@ | sort -u
    RAILS3_IVARS = [:@aggregation_cache, :@arel_engine, :@arel_table, :@association_cache, :@attributes_cache, :@attributes, :@changed_attributes, :@column_names, :@columns, :@columns_hash, :@content_columns, :@destroyed, :@dynamic_methods_hash, :@errors, :@finder_needs_type_condition, :@generated_feature_methods, :@inheritance_column, :@marked_for_destruction, :@new_record, :@new_record_before_save, :@previously_changed, :@quoted_table_name, :@readonly, :@relation, :@validation_context]
    
    ACTIVE_RECORD_INSTANCE_VARIABLES = ::ActiveRecord::VERSION::MAJOR == 3 ? RAILS3_IVARS : RAILS2_IVARS

    DELAYED_JOB_INSTANCE_VARIABLES = [:@payload_object]

    # Serialize any transient attributes too
    def encode_with(coder)
      super(coder) if defined?(super)
      return if coder.blank?

      # From delayed_job/lib/delayed/psych_ext.rb
      coder["attributes"] = @attributes
      coder.tag = ['!ruby/ActiveRecord', self.class.name].join(':')
      
      ivars_without_ar = instance_variables.reject {|x| ACTIVE_RECORD_INSTANCE_VARIABLES.include?(x)}
      ivars_without_assoc = ivars_without_ar.reject{|x| _is_association?(x.to_s.sub(/@/, '').to_sym)}
      transient_attrs = ivars_without_assoc.reject {|x| DELAYED_JOB_INSTANCE_VARIABLES.include?(x)}

      transient_attrs.each do |tvar|
        tvar_name = tvar.to_s.sub(/@/, '')
        next  if ! respond_to?("#{tvar_name}=")
        coder[tvar_name] = instance_variable_get(tvar)
      end
        
    end
    
    # Deserialize any transient attributes too
    def init_with(coder)
      return if coder.blank?

      if ::ActiveRecord::VERSION::MAJOR == 3
        r = _init_with_active_record_3_0(coder) if ::ActiveRecord::VERSION::MINOR == 0
        r = _init_with_active_record_3_1(coder) if ::ActiveRecord::VERSION::MINOR == 1
      end
      
      _run_initialize_transient_attributes(coder)
      return r
    end

    private
    
      # From lib/active_record/base.rb
      def _init_with_active_record_3_0(coder)
        @attributes = coder['attributes']
        @attributes_cache, @previously_changed, @changed_attributes = {}, {}, {}
        @new_record = @readonly = @destroyed = @marked_for_destruction = false
        _run_find_callbacks
        _run_initialize_callbacks
      end
      
      # From lib/active_record/base.rb
      def _init_with_active_record_3_1(coder)
        @attributes = coder['attributes']
        @relation = nil

        set_serialized_attributes

        @attributes_cache, @previously_changed, @changed_attributes = {}, {}, {}
        @association_cache = {}
        @aggregation_cache = {}
        @readonly = @destroyed = @marked_for_destruction = false
        @new_record = false
        run_callbacks :find
        run_callbacks :initialize

        self
      end
      
      def _is_association?(ivar_name)
        return false if ivar_name.blank?
        return ! self.class.reflections.select{|r| r == ivar_name.to_sym}.empty?
      end
    
      def _run_initialize_transient_attributes(coder)
        return if coder.blank?
      
        vars = coder.reject{|name,value| name == 'attributes'}
        transient_vars = vars.reject{|name,value| _is_association?(name)}

        transient_vars.each_pair do |name,value|
          next if ! respond_to?("#{name}=")
          send("#{name}=", value)
        end
      
        self
      end

  end
end

module Delayed
  module Backend
    module ActiveRecord
      # A job object that is persisted to the database.
      # Contains the work object as a YAML field.
      class Job < ::ActiveRecord::Base
        include Delayed::Backend::Base

        attr_accessible :priority, :run_at, :queue, :payload_object,
          :failed_at, :locked_at, :locked_by

        before_save :set_default_run_at

        def self.rails3?
          ::ActiveRecord::VERSION::MAJOR == 3
        end

        if rails3?
          self.table_name = 'delayed_jobs'
          scope :ready_to_run, lambda{|worker_name, max_run_time|
            where('(run_at <= ? AND (locked_at IS NULL OR locked_at < ?) OR locked_by = ?) AND failed_at IS NULL', db_time_now, db_time_now - max_run_time, worker_name)
          }
          scope :by_priority, order('priority ASC, run_at ASC')
        else
          set_table_name :delayed_jobs
          named_scope :ready_to_run, lambda {|worker_name, max_run_time|
            { :conditions => ['(run_at <= ? AND (locked_at IS NULL OR locked_at < ?) OR locked_by = ?) AND failed_at IS NULL', db_time_now, db_time_now - max_run_time, worker_name] }
          }
          named_scope :by_priority, :order => 'priority ASC, run_at ASC'
        end

        def self.before_fork
          ::ActiveRecord::Base.clear_all_connections!
        end

        def self.after_fork
          ::ActiveRecord::Base.establish_connection
        end

        # When a worker is exiting, make sure we don't have any locked jobs.
        def self.clear_locks!(worker_name)
          update_all("locked_by = null, locked_at = null", ["locked_by = ?", worker_name])
        end

        # Find a few candidate jobs to run (in case some immediately get locked by others).
        def self.find_available(worker_name, limit = 5, max_run_time = Worker.max_run_time)
          scope = self.ready_to_run(worker_name, max_run_time)
          scope = scope.scoped(:conditions => ['priority >= ?', Worker.min_priority]) if Worker.min_priority
          scope = scope.scoped(:conditions => ['priority <= ?', Worker.max_priority]) if Worker.max_priority
          scope = scope.scoped(:conditions => ["queue IN (?)", Worker.queues]) if Worker.queues.any?

          ::ActiveRecord::Base.silence do
            scope.by_priority.all(:limit => limit)
          end
        end

        # Lock this job for this worker.
        # Returns true if we have the lock, false otherwise.
        def lock_exclusively!(max_run_time, worker)
          now = self.class.db_time_now
          affected_rows = if locked_by != worker
            # We don't own this job so we will update the locked_by name and the locked_at
            self.class.update_all(["locked_at = ?, locked_by = ?", now, worker], ["id = ? and (locked_at is null or locked_at < ?) and (run_at <= ?)", id, (now - max_run_time.to_i), now])
          else
            # We already own this job, this may happen if the job queue crashes.
            # Simply resume and update the locked_at
            self.class.update_all(["locked_at = ?", now], ["id = ? and locked_by = ?", id, worker])
          end
          if affected_rows == 1
            self.locked_at = now
            self.locked_by = worker
            self.locked_at_will_change!
            self.locked_by_will_change!
            return true
          else
            return false
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
