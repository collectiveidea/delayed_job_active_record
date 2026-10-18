# frozen_string_literal: true

require "helper"
require "delayed/backend/active_record"

describe Delayed::Backend::ActiveRecord::Job do
  it_behaves_like "a delayed_job backend"

  describe "configuration" do
    describe "reserve_sql_strategy" do
      let(:configuration) { Delayed::Backend::ActiveRecord.configuration }

      it "allows :optimized_sql" do
        configuration.reserve_sql_strategy = :optimized_sql
        expect(configuration.reserve_sql_strategy).to eq(:optimized_sql)
      end

      it "allows :default_sql" do
        configuration.reserve_sql_strategy = :default_sql
        expect(configuration.reserve_sql_strategy).to eq(:default_sql)
      end

      it "raises an argument error on invalid entry" do
        expect { configuration.reserve_sql_strategy = :invalid }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      expect { |block| Delayed::Backend::ActiveRecord.configure(&block) }
        .to yield_with_args(Delayed::Backend::ActiveRecord.configuration)
    end
  end

  # The reservation strategies below are specific to a database, but
  # their SQL is built and executed by the methods here, so these specs
  # exercise each of them against whichever database the suite runs on,
  # stubbing only the calls that would need that particular database
  describe "reservation" do
    let(:worker) { instance_double(Delayed::Worker, name: "worker01", read_ahead: 5) }
    let(:now) { described_class.db_time_now.change(usec: 0) }
    let(:ready_scope) { described_class.ready_to_run(worker.name, Delayed::Worker.max_run_time).by_priority }
    let(:quoted_table_name) { described_class.connection.quote_table_name(described_class.table_name) }

    before do
      described_class.delete_all
    end

    # Far enough in the past to be ready regardless of the time zone
    def create_ready_job
      described_class.create!(payload_object: SimpleJob.new, run_at: 1.day.ago)
    end

    describe ".reserve_with_scope" do
      let(:configuration) { Delayed::Backend::ActiveRecord.configuration }

      before do
        allow(described_class).to receive_messages(
          reserve_with_scope_using_optimized_sql: :optimized,
          reserve_with_scope_using_default_sql: :default
        )
      end

      after do
        configuration.reserve_sql_strategy = :optimized_sql
      end

      it "uses the optimized SQL with reserve_sql_strategy set to :optimized_sql (default)" do
        configuration.reserve_sql_strategy = :optimized_sql
        expect(described_class.reserve_with_scope(ready_scope, worker, now)).to eq(:optimized)
        expect(described_class).to have_received(:reserve_with_scope_using_optimized_sql).with(ready_scope, worker, now)
      end

      it "uses the plain SQL with reserve_sql_strategy set to :default_sql" do
        configuration.reserve_sql_strategy = :default_sql
        expect(described_class.reserve_with_scope(ready_scope, worker, now)).to eq(:default)
        expect(described_class).to have_received(:reserve_with_scope_using_default_sql).with(ready_scope, worker, now)
      end
    end

    describe ".reserve_with_scope_using_optimized_sql" do
      {
        "PostgreSQL" => :reserve_with_scope_using_optimized_postgres,
        "PostGIS" => :reserve_with_scope_using_optimized_postgres,
        "MySQL" => :reserve_with_scope_using_optimized_mysql,
        "Mysql2" => :reserve_with_scope_using_optimized_mysql,
        "Trilogy" => :reserve_with_scope_using_optimized_mysql,
        "MSSQL" => :reserve_with_scope_using_optimized_mssql,
        "Teradata" => :reserve_with_scope_using_optimized_mssql,
        "OtherDB" => :reserve_with_scope_using_default_sql
      }.each do |adapter_name, strategy|
        it "uses #{strategy} for the #{adapter_name} adapter" do
          allow(described_class.connection).to receive(:adapter_name).and_return(adapter_name)
          allow(described_class).to receive(strategy).and_return(:job)
          expect(described_class.reserve_with_scope_using_optimized_sql(ready_scope, worker, now)).to eq(:job)
          expect(described_class).to have_received(strategy).with(ready_scope, worker, now)
        end
      end
    end

    describe ".reserve_with_scope_using_default_sql" do
      it "locks and returns the next ready job" do
        job = create_ready_job
        reserved = described_class.reserve_with_scope_using_default_sql(ready_scope, worker, now)
        expect(reserved).to eq(job)
        expect(reserved.locked_by).to eq("worker01")
        expect(reserved.locked_at).to eq(now)
      end

      it "returns nil when no job is ready" do
        expect(described_class.reserve_with_scope_using_default_sql(ready_scope, worker, now)).to be_nil
      end
    end

    describe ".reserve_with_scope_using_optimized_postgres" do
      let(:subquery) { ready_scope.limit(1).lock(true).select("id").to_sql }

      before do
        allow(described_class).to receive(:find_by_sql).and_return([:job])
      end

      def reserve_on_postgresql_version(version)
        allow(described_class.connection).to receive(:postgresql_version).and_return(version)
        described_class.reserve_with_scope_using_optimized_postgres(ready_scope, worker, now)
      end

      it "locks and returns the next ready job in one UPDATE, skipping locked rows" do
        expect(reserve_on_postgresql_version(9_05_00)).to eq(:job) # rubocop:disable Style/NumericLiterals
        expect(described_class).to have_received(:find_by_sql).with(
          [
            "UPDATE #{quoted_table_name} SET locked_at = ?, locked_by = ? " \
            "WHERE id IN (#{subquery} SKIP LOCKED) RETURNING *",
            now,
            "worker01"
          ]
        )
      end

      it "doesn't skip locked rows before PostgreSQL 9.5" do
        expect(reserve_on_postgresql_version(9_04_00)).to eq(:job) # rubocop:disable Style/NumericLiterals
        expect(described_class).to have_received(:find_by_sql).with(
          [
            "UPDATE #{quoted_table_name} SET locked_at = ?, locked_by = ? WHERE id IN (#{subquery}) RETURNING *",
            now,
            "worker01"
          ]
        )
      end
    end

    describe ".reserve_with_scope_using_optimized_mysql" do
      it "locks and returns the next ready job, dropping sub-second precision" do
        job = create_ready_job
        reserved = described_class.reserve_with_scope_using_optimized_mysql(ready_scope, worker, now + 0.5)
        expect(reserved).to eq(job)
        expect(reserved.locked_by).to eq("worker01")
        expect(reserved.locked_at).to eq(now)
      end

      it "returns nil when no job is ready" do
        expect(described_class.reserve_with_scope_using_optimized_mysql(ready_scope, worker, now)).to be_nil
      end
    end

    describe ".reserve_with_scope_using_optimized_mssql" do
      let(:update_sql) do
        # sanitize_sql is protected before Rails 5.2
        described_class.send(
          :sanitize_sql,
          [
            "UPDATE #{quoted_table_name} SET locked_at = ?, locked_by = ? " \
            "WHERE id IN (SELECT id FROM (#{ready_scope.limit(1).to_sql}) AS x)",
            now,
            "worker01"
          ]
        )
      end

      # Stub the UPDATE alone, since some adapters run their queries
      # through execute too
      def stub_update_count(count)
        allow(described_class.connection).to receive(:execute).and_call_original
        allow(described_class.connection).to receive(:execute).with(update_sql).and_return(count)
      end

      it "locks the next ready job in one UPDATE and returns it" do
        job = described_class.create!(payload_object: SimpleJob.new, locked_at: now, locked_by: "worker01")
        stub_update_count(1)
        expect(described_class.reserve_with_scope_using_optimized_mssql(ready_scope, worker, now)).to eq(job)
      end

      it "returns nil when the UPDATE locks no job" do
        stub_update_count(0)
        expect(described_class.reserve_with_scope_using_optimized_mssql(ready_scope, worker, now)).to be_nil
      end
    end
  end

  context "db_time_now" do
    def use_default_timezone(timezone)
      if ActiveRecord.respond_to?(:default_timezone=)
        ActiveRecord.default_timezone = timezone
      else
        ActiveRecord::Base.default_timezone = timezone
      end
    end

    after do
      Time.zone = nil
      use_default_timezone(:local)
    end

    it "returns time in current time zone if set" do
      Time.zone = "Arizona"
      expect(Delayed::Job.db_time_now.zone).to eq("MST")
    end

    it "returns UTC time if that is the AR default" do
      Time.zone = nil
      use_default_timezone(:utc)
      expect(Delayed::Backend::ActiveRecord::Job.db_time_now.zone).to eq "UTC"
    end

    it "returns local time if that is the AR default" do
      Time.zone = "Arizona"
      use_default_timezone(:local)
      expect(Delayed::Backend::ActiveRecord::Job.db_time_now.zone).to eq("MST")
    end
  end

  describe "default_timezone" do
    it "reads ActiveRecord.default_timezone on Rails 7.0 and later" do
      allow(ActiveRecord).to receive(:respond_to?).and_call_original
      allow(ActiveRecord).to receive(:respond_to?).with(:default_timezone).and_return(true)
      allow(ActiveRecord).to receive(:default_timezone).and_return(:local)
      expect(Delayed::Backend::ActiveRecord::Job.default_timezone).to eq(:local)
    end

    it "reads ActiveRecord::Base.default_timezone before Rails 7.0" do
      allow(ActiveRecord).to receive(:respond_to?).and_call_original
      allow(ActiveRecord).to receive(:respond_to?).with(:default_timezone).and_return(false)
      allow(ActiveRecord::Base).to receive(:default_timezone).and_return(:local)
      expect(Delayed::Backend::ActiveRecord::Job.default_timezone).to eq(:local)
    end
  end

  describe "before_fork" do
    let(:connection_handler) { ActiveRecord::Base.connection_handler }

    before do
      allow(connection_handler).to receive(:clear_all_connections!)
    end

    it "clears the connections for all roles on Rails 7.1 and later" do
      stub_const("ActiveRecord::VERSION::STRING", "7.1.0")
      Delayed::Backend::ActiveRecord::Job.before_fork
      expect(connection_handler).to have_received(:clear_all_connections!).with(:all)
    end

    it "clears all connections before Rails 7.1" do
      stub_const("ActiveRecord::VERSION::STRING", "7.0.8")
      Delayed::Backend::ActiveRecord::Job.before_fork
      expect(connection_handler).to have_received(:clear_all_connections!).with(no_args)
    end
  end

  describe "after_fork" do
    it "calls reconnect on the connection" do
      allow(ActiveRecord::Base).to receive(:establish_connection)
      Delayed::Backend::ActiveRecord::Job.after_fork
      expect(ActiveRecord::Base).to have_received(:establish_connection)
    end
  end

  describe "enqueue" do
    it "allows enqueue hook to modify job at DB level" do
      later = described_class.db_time_now + 20.minutes
      job = Delayed::Backend::ActiveRecord::Job.enqueue payload_object: EnqueueJobMod.new
      expect(Delayed::Backend::ActiveRecord::Job.find(job.id).run_at).to be_within(1).of(later)
    end
  end

  if ActiveRecord::VERSION::MAJOR < 4 || defined?(ActiveRecord::MassAssignmentSecurity)
    context "ActiveRecord::Base.send(:attr_accessible, nil)" do
      before do
        Delayed::Backend::ActiveRecord::Job.send(:attr_accessible, nil)
      end

      after do
        Delayed::Backend::ActiveRecord::Job.send(
          :attr_accessible,
          *Delayed::Backend::ActiveRecord::Job.new.attributes.keys
        )
      end

      it "is still accessible" do
        job = Delayed::Backend::ActiveRecord::Job.enqueue payload_object: EnqueueJobMod.new
        expect(Delayed::Backend::ActiveRecord::Job.find(job.id).handler).not_to be_blank
      end
    end
  end

  context "ActiveRecord::Base.table_name_prefix" do
    it "when prefix is not set, use 'delayed_jobs' as table name" do
      ActiveRecord::Base.table_name_prefix = nil
      Delayed::Backend::ActiveRecord::Job.set_delayed_job_table_name

      expect(Delayed::Backend::ActiveRecord::Job.table_name).to eq "delayed_jobs"
    end

    it "when prefix is set, prepend it before default table name" do
      ActiveRecord::Base.table_name_prefix = "custom_"
      Delayed::Backend::ActiveRecord::Job.set_delayed_job_table_name

      expect(Delayed::Backend::ActiveRecord::Job.table_name).to eq "custom_delayed_jobs"

      ActiveRecord::Base.table_name_prefix = nil
      Delayed::Backend::ActiveRecord::Job.set_delayed_job_table_name
    end
  end
end
