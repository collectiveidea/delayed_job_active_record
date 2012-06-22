require 'spec_helper'
require 'delayed/backend/active_record'

describe Delayed::Backend::ActiveRecord::Job do
  after do
    Time.zone = nil
  end

  it_should_behave_like 'a delayed_job backend'

  context "db_time_now" do
    it "should return time in current time zone if set" do
      Time.zone = 'Eastern Time (US & Canada)'
      %w(EST EDT).should include(Delayed::Job.db_time_now.zone)
    end

    it "should return UTC time if that is the AR default" do
      Time.zone = nil
      ActiveRecord::Base.default_timezone = :utc
      Delayed::Backend::ActiveRecord::Job.db_time_now.zone.should == 'UTC'
    end

    it "should return local time if that is the AR default" do
      Time.zone = 'Central Time (US & Canada)'
      ActiveRecord::Base.default_timezone = :local
      %w(CST CDT).should include(Delayed::Backend::ActiveRecord::Job.db_time_now.zone)
    end
  end

  describe "after_fork" do
    it "should call reconnect on the connection" do
      ActiveRecord::Base.should_receive(:establish_connection)
      Delayed::Backend::ActiveRecord::Job.after_fork
    end
  end

  describe "enqueue" do
    it "should allow enqueue hook to modify job at DB level" do
      later = described_class.db_time_now + 20.minutes
      job = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => EnqueueJobMod.new
      Delayed::Backend::ActiveRecord::Job.find(job.id).run_at.should be_within(1).of(later)
    end
  end

  context "ActiveRecord::Base.send(:attr_accessible, nil)" do
    before do
      Delayed::Backend::ActiveRecord::Job.send(:attr_accessible, nil)
    end

    after do
      Delayed::Backend::ActiveRecord::Job.send(:attr_accessible, *Delayed::Backend::ActiveRecord::Job.new.attributes.keys)
    end

    it "should still be accessible" do
      job = Delayed::Backend::ActiveRecord::Job.enqueue :payload_object => EnqueueJobMod.new
      Delayed::Backend::ActiveRecord::Job.find(job.id).handler.should_not be_blank
    end
  end

  context "ActiveRecord::Base.table_name_prefix" do
    def reload_job_class_definition
      # If this can be done in a more sane manner, please fix it
      load File.join File.dirname(__FILE__), '..', '..', '..', 'lib', 'delayed', 'backend', 'active_record.rb'
    end

    it "when prefix is not set, should use 'delayed_jobs' as table name" do
      ::ActiveRecord::Base.table_name_prefix = nil
      reload_job_class_definition
      Delayed::Backend::ActiveRecord::Job.table_name.should eq 'delayed_jobs'
    end

    it "when prefix is set, should prepend it before default table name" do
      ::ActiveRecord::Base.table_name_prefix = 'custom_'
      reload_job_class_definition
      Delayed::Backend::ActiveRecord::Job.table_name.should eq 'custom_delayed_jobs'
    end
  end
end
