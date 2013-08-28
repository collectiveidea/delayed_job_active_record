require 'helper'
require 'delayed/backend/active_record'

describe Delayed::Backend::ActiveRecord::Job do
  it_behaves_like 'a delayed_job backend'

  context "db_time_now" do
    after do
      Time.zone = nil
      ActiveRecord::Base.default_timezone = :local
    end

    it "returns time in current time zone if set" do
      Time.zone = 'Eastern Time (US & Canada)'
      expect(%(EST EDT)).to include(Delayed::Job.db_time_now.zone)
    end

    it "returns UTC time if that is the AR default" do
      Time.zone = nil
      ActiveRecord::Base.default_timezone = :utc
      expect(Delayed::Backend::ActiveRecord::Job.db_time_now.zone).to eq 'UTC'
    end

    it "returns local time if that is the AR default" do
      Time.zone = 'Central Time (US & Canada)'
      ActiveRecord::Base.default_timezone = :local
      expect(%w(CST CDT)).to include(Delayed::Backend::ActiveRecord::Job.db_time_now.zone)
    end
  end

  describe "after_fork" do
    it "calls reconnect on the connection" do
      ActiveRecord::Base.should_receive(:establish_connection)
      Delayed::Backend::ActiveRecord::Job.after_fork
    end
  end

  describe "enqueue" do
    it "allows enqueue hook to modify job at DB level" do
      later = described_class.db_time_now + 20.minutes
      job = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => EnqueueJobMod.new
      expect(Delayed::Backend::ActiveRecord::Job.find(job.id).run_at).to be_within(1).of(later)
    end
  end

  describe "process" do
    it "reserves jobs from the correct queue" do
      # clear any jobs sitting around
      Delayed::Backend::ActiveRecord::Job.delete_all

      job = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => SimpleJob.new, :queue => 'queue'
      Delayed::Backend::ActiveRecord::Job.count.should == 1
      Delayed::Worker.new(:queue => 'queue').work_off
      Delayed::Backend::ActiveRecord::Job.count.should == 0
    end

    if Delayed::Worker.respond_to?(:excludes)
      it "ignores excluded queues when reserving jobs" do
        # clear any jobs sitting around
        Delayed::Backend::ActiveRecord::Job.delete_all

        job = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => SimpleJob.new, :queue => 'process'
        excluded_job = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => SimpleJob.new, :queue => 'ignore'
        Delayed::Worker.excludes << 'ignore'
        Delayed::Worker.new.work_off

        Delayed::Backend::ActiveRecord::Job.find(excluded_job.id).queue.should == 'ignore'
        Delayed::Backend::ActiveRecord::Job.count.should == 1
      end
    end
  end

  if ::ActiveRecord::VERSION::MAJOR < 4 || defined?(::ActiveRecord::MassAssignmentSecurity)
    context "ActiveRecord::Base.send(:attr_accessible, nil)" do
      before do
        Delayed::Backend::ActiveRecord::Job.send(:attr_accessible, nil)
      end

      after do
        Delayed::Backend::ActiveRecord::Job.send(:attr_accessible, *Delayed::Backend::ActiveRecord::Job.new.attributes.keys)
      end

      it "is still accessible" do
        job = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => EnqueueJobMod.new
        expect(Delayed::Backend::ActiveRecord::Job.find(job.id).handler).to_not be_blank
      end
    end
  end

  context "ActiveRecord::Base.table_name_prefix" do
    it "when prefix is not set, use 'delayed_jobs' as table name" do
      ::ActiveRecord::Base.table_name_prefix = nil
      Delayed::Backend::ActiveRecord::Job.set_delayed_job_table_name

      expect(Delayed::Backend::ActiveRecord::Job.table_name).to eq 'delayed_jobs'
    end

    it "when prefix is set, prepend it before default table name" do
      ::ActiveRecord::Base.table_name_prefix = 'custom_'
      Delayed::Backend::ActiveRecord::Job.set_delayed_job_table_name

      expect(Delayed::Backend::ActiveRecord::Job.table_name).to eq 'custom_delayed_jobs'

      ::ActiveRecord::Base.table_name_prefix = nil
      Delayed::Backend::ActiveRecord::Job.set_delayed_job_table_name
    end
  end
end
