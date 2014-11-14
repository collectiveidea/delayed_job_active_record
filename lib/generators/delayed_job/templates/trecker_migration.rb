class AddTreckerStaffIdToDelayedJobs < ActiveRecord::Migration
  def self.up
    add_column :delayed_jobs, :staff_id, :integer
  end

  def self.down
    remove_column :delayed_jobs, :staff_id
  end
end
