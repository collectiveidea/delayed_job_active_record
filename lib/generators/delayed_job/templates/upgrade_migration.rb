class AddQueueToDelayedJobs < ActiveRecord::Migration
  def change
    add_column :delayed_jobs, :queue, :string
  end
end
