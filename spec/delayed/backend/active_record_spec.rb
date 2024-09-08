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
        expect { configuration.reserve_sql_strategy = :invald }.to raise_error(ArgumentError)
      end
    end
  end

  describe "reserve_with_scope" do
    let(:relation_class) { Delayed::Job.limit(1).class }
    let(:worker) { instance_double(Delayed::Worker, name: "worker01", read_ahead: 1) }
    let(:limit) { instance_double(relation_class, update_all: 0) }
    let(:where) { instance_double(relation_class, update_all: 0) }
    let(:scope) { instance_double(relation_class, limit: limit, where: where) }
    let(:job) { instance_double(Delayed::Job, id: 1) }

    before do
      allow(Delayed::Backend::ActiveRecord::Job.connection).to receive(:adapter_name).at_least(:once).and_return(dbms)
      Delayed::Backend::ActiveRecord.configuration.reserve_sql_strategy = reserve_sql_strategy
    end

    context "with reserve_sql_strategy option set to :optimized_sql (default)" do
      let(:reserve_sql_strategy) { :optimized_sql }

      context "for mysql adapters" do
        let(:dbms) { "MySQL" }

        it "uses the optimized sql version" do
          allow(Delayed::Backend::ActiveRecord::Job).to receive(:reserve_with_scope_using_default_sql)
          Delayed::Backend::ActiveRecord::Job.reserve_with_scope(scope, worker, Time.current)
          expect(Delayed::Backend::ActiveRecord::Job).not_to have_received(:reserve_with_scope_using_default_sql)
        end
      end

      context "for a dbms without a specific implementation" do
        let(:dbms) { "OtherDB" }

        it "uses the plain sql version" do
          allow(Delayed::Backend::ActiveRecord::Job).to receive(:reserve_with_scope_using_default_sql)
          Delayed::Backend::ActiveRecord::Job.reserve_with_scope(scope, worker, Time.current)
          expect(Delayed::Backend::ActiveRecord::Job).to have_received(:reserve_with_scope_using_default_sql).once
        end
      end
    end

    context "with reserve_sql_strategy option set to :default_sql" do
      let(:dbms) { "MySQL" }
      let(:reserve_sql_strategy) { :default_sql }

      it "uses the plain sql version" do
        allow(Delayed::Backend::ActiveRecord::Job).to receive(:reserve_with_scope_using_default_sql)
        Delayed::Backend::ActiveRecord::Job.reserve_with_scope(scope, worker, Time.current)
        expect(Delayed::Backend::ActiveRecord::Job).to have_received(:reserve_with_scope_using_default_sql).once
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

  describe "before_fork" do
    it "clears all connections connection" do
      allow(ActiveRecord::Base.connection_handler).to receive(:clear_all_connections!)
      Delayed::Backend::ActiveRecord::Job.before_fork

      if Gem::Version.new("7.1.0") <= Gem::Version.new(ActiveRecord::VERSION::STRING)
        expect(ActiveRecord::Base.connection_handler).to have_received(:clear_all_connections!).with(:all)
      else
        expect(ActiveRecord::Base.connection_handler).to have_received(:clear_all_connections!)
      end
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
