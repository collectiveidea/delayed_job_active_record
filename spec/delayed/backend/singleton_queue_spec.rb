require 'helper'
require 'delayed/backend/active_record'

describe "Singleton Job Queue" do
  class TestSingleton
    attr_reader :singleton_queue_name

    def initialize(singleton_queue_name)
      @singleton_queue_name = singleton_queue_name
    end

    def perform; end
  end

  class TestNonSingleton
    def perform; end
  end

  describe "mix of singleton and non-singelton jobs" do
    let(:queue_name) { "test_queue_name" }
    let(:worker1) { double(:worker, name: "worker1", read_ahead: 1) }
    let(:worker2) { double(:worker, name: "worker2", read_ahead: 1) }

    after do
      Delayed::Job.destroy_all
    end

    context "the non-singleton job is enqueued first" do
      before do
        Delayed::Job.enqueue(TestNonSingleton.new)
        Delayed::Job.enqueue(TestSingleton.new(queue_name))
      end

      it "reserves both jobs" do
        Delayed::Job.reserve(worker1)
        Delayed::Job.reserve(worker2)

        # There should be two jobs on the queue, both locked
        expect(Delayed::Job.count).to eq(2)
        expect(Delayed::Job.where(singleton: nil, locked_by: worker1.name).count).to eq(1)
        expect(Delayed::Job.where(singleton: queue_name, locked_by: worker2.name).count).to eq(1)
      end
    end

    context "the singleton job is enqueued first" do
      before do
        Delayed::Job.enqueue(TestSingleton.new(queue_name))
        Delayed::Job.enqueue(TestNonSingleton.new)
      end

      it "reserves both jobs" do
        Delayed::Job.reserve(worker1)
        Delayed::Job.reserve(worker2)

        # There should be two jobs on the queue, both locked
        expect(Delayed::Job.count).to eq(2)
        expect(Delayed::Job.where(singleton: queue_name, locked_by: worker1.name).count).to eq(1)
        expect(Delayed::Job.where(singleton: nil, locked_by: worker2.name).count).to eq(1)
      end
    end
  end

  context "two jobs with the same singleton_queue_name" do
    let(:queue_name) { "test_queue_name" }
    let(:different_queue_name) { "different_test_queue" }
    let(:worker1) { double(:worker, name: "worker1", read_ahead: 1) }
    let(:worker2) { double(:worker, name: "worker2", read_ahead: 1) }

    before do
      Delayed::Job.enqueue(TestSingleton.new(queue_name))
      Delayed::Job.enqueue(TestSingleton.new(queue_name))
    end

    after do
      Delayed::Job.destroy_all
    end

    it "will only reserve one of the two jobs" do
      Delayed::Job.reserve(worker1)
      Delayed::Job.reserve(worker2)

      # There should be two jobs on the queue, one locked and one not locked
      expect(Delayed::Job.where(singleton: queue_name).count).to eq(2)
      expect(Delayed::Job.where(singleton: queue_name, locked_by: worker1.name).count).to eq(1)
      expect(Delayed::Job.where(singleton: queue_name, locked_by: nil).count).to eq(1)
    end

    context "when one of the jobs is locked" do
      let!(:locked_job) { Delayed::Job.reserve(worker1) }

      context "and the locked job is failed" do
        let(:failure_time) { Time.now }

        before do
          locked_job.update_attributes(failed_at: failure_time)
        end

        it "will pick up the remaining job" do
          Delayed::Job.reserve(worker1)
          Delayed::Job.reserve(worker2)

          # There should be two jobs on the queue, both locked and one failed
          expect(Delayed::Job.where(singleton: queue_name).count).to eq(2)
          expect(Delayed::Job.where(singleton: queue_name, locked_by: worker1.name).count).to eq(2)
          expect(Delayed::Job.where(singleton: queue_name, failed_at: failure_time).count).to eq(1)
        end
      end

      context "the locked job is expired" do
        before do
          locked_job.update_attributes(locked_at: Date.new(2000, 1, 1))
        end

        it "will pick up a job" do
          Delayed::Job.reserve(worker1)
          Delayed::Job.reserve(worker2)

          # There should be two jobs on the queue, one locked and one not locked
          expect(Delayed::Job.where(singleton: queue_name).count).to eq(2)
          expect(Delayed::Job.where(singleton: queue_name, locked_by: worker1.name).count).to eq(1)
          expect(Delayed::Job.where(singleton: queue_name, locked_by: nil).count).to eq(1)
        end
      end

      context "with a job in a different singleton queue" do
        before do
          Delayed::Job.enqueue(TestSingleton.new(different_queue_name))
        end

        it "will reserve the job from the other queue" do
          Delayed::Job.reserve(worker1)
          Delayed::Job.reserve(worker2)

          # There should be three jobs on the queue, one not locked and one from each queue locked
          expect(Delayed::Job.where(singleton: queue_name).count).to eq(2)
          expect(Delayed::Job.where(singleton: queue_name, locked_by: worker1.name).count).to eq(1)
          expect(Delayed::Job.where(singleton: queue_name, locked_by: nil).count).to eq(1)
          expect(Delayed::Job.where(singleton: different_queue_name).count).to eq(1)
          expect(Delayed::Job.where(singleton: different_queue_name, locked_by: worker2.name).count).to eq(1)
        end
      end

      context "with a non-singleton-queue-job" do
        before do
          Delayed::Job.enqueue(payload_object: TestNonSingleton.new, singleton: different_queue_name)
        end

        it "will reserve the non-singleton-queue job" do
          Delayed::Job.reserve(worker1)
          Delayed::Job.reserve(worker2)

          # There should be three jobs on the queue, one locked singleton, one not locked singleton, one locked non-singleton
          expect(Delayed::Job.where(singleton: queue_name).count).to eq(2)
          expect(Delayed::Job.where(singleton: queue_name, locked_by: worker1.name).count).to eq(1)
          expect(Delayed::Job.where(singleton: queue_name, locked_by: nil).count).to eq(1)
          expect(Delayed::Job.where(singleton: different_queue_name).count).to eq(1)
          expect(Delayed::Job.where(singleton: different_queue_name, locked_by: worker2.name).count).to eq(1)
        end
      end

      context "with a null-queue job" do
        before do
          Delayed::Job.enqueue(TestNonSingleton.new)
        end

        it "will reserve the null-queue job" do
          Delayed::Job.reserve(worker1)
          Delayed::Job.reserve(worker2)

          # There should be three jobs on the queue, one locked singleton, one not locked singleton, one locked null
          expect(Delayed::Job.where(singleton: queue_name).count).to eq(2)
          expect(Delayed::Job.where(singleton: queue_name, locked_by: worker1.name).count).to eq(1)
          expect(Delayed::Job.where(singleton: queue_name, locked_by: nil).count).to eq(1)
          expect(Delayed::Job.where(singleton: nil).count).to eq(1)
          expect(Delayed::Job.where(singleton: nil, locked_by: worker2.name).count).to eq(1)
        end
      end
    end

    describe '.retry_on_deadlock' do
      context "when there is a deadlock exception raised in the block" do
        let(:max_retries) { 5 }

        it "will retry max_retries times and then raise the exception" do
          Delayed::Job.should_receive(:sleep).exactly(max_retries).times

          expect do
            Delayed::Job.retry_on_deadlock(max_retries) do
              # The exception will be an ActiveRecord::StatementInvalid, but we can
              # avoid making a new dependency on that class by just checking the message here.
              raise StandardError.new("Exception: Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction: <transaction details>")
            end
          end.to raise_error(StandardError)
        end
      end
    end

  end

end
