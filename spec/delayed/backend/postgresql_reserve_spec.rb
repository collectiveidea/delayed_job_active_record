# frozen_string_literal: true

require "helper"

# Integration test for https://github.com/collectiveidea/delayed_job_active_record/issues/143
#
# The optimized PostgreSQL reserve statement is
#
#   UPDATE delayed_jobs SET locked_at = ?, locked_by = ?
#   WHERE id IN (SELECT id FROM delayed_jobs WHERE <ready> ORDER BY priority, run_at LIMIT 1 FOR UPDATE SKIP LOCKED)
#   RETURNING *
#
# When the planner runs the sub-select as the inner side of a Nested Loop Semi Join it re-executes
# the sub-select for every candidate row. Each execution reads the latest row versions and skips the
# rows this UPDATE already changed, so one reserve locks the whole ready batch under one worker name
# (see pgsql-bugs #15715). Which plan the planner picks depends on table statistics, so the settings
# below disable every other join strategy and make the rescanning plan deterministic.
describe Delayed::Backend::ActiveRecord::Job do
  describe ".reserve on PostgreSQL" do
    let(:worker) { Delayed::Worker.new }
    let(:ready_jobs) { 5 }

    before do
      skip "PostgreSQL only" unless described_class.connection.adapter_name.start_with?("PostgreSQL", "PostGIS")

      Delayed::Backend::ActiveRecord.configuration.reserve_sql_strategy = :optimized_sql
      described_class.delete_all
      ready_jobs.times do |n|
        run_at = described_class.db_time_now - (60 * (ready_jobs - n))
        described_class.create!(payload_object: SimpleJob.new, run_at: run_at)
      end
    end

    def with_rescanning_planner
      described_class.transaction do
        described_class.connection.execute(
          %w[enable_hashjoin enable_mergejoin enable_material enable_hashagg enable_sort]
            .map { |setting| "SET LOCAL #{setting} = off" }.join("; ")
        )
        yield
        raise ActiveRecord::Rollback
      end
    end

    def reserve_sql
      ready_scope = described_class.ready_to_run(worker.name, Delayed::Worker.max_run_time).by_priority
      subquery = "#{ready_scope.limit(1).lock(true).select('id').to_sql} SKIP LOCKED"
      "UPDATE delayed_jobs SET locked_at = now(), locked_by = '#{worker.name}' WHERE id IN (#{subquery}) RETURNING *"
    end

    it "re-executes the sub-select for every candidate row with these planner settings" do
      with_rescanning_planner do
        plan = described_class.connection.execute("EXPLAIN #{reserve_sql}").values.flatten.join("\n")
        expect(plan).to include("Nested Loop Semi Join")
      end
    end

    it "locks exactly one job per reserve" do
      with_rescanning_planner do
        described_class.reserve(worker)
        expect(described_class.where(locked_by: worker.name).count).to eq(1)
      end
    end
  end
end
