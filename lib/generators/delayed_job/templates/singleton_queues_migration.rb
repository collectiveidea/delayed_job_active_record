class AddSingletonToDelayedJobs < ActiveRecord::Migration
  def self.up
    add_column :delayed_jobs, :singleton, :string
    execute "UPDATE delayed_jobs SET singleton = substr(queue, #{'singleton_'.length + 1}, 255) WHERE queue like 'singleton_%'"
  end

  def self.down
    remove_column :delayed_jobs, :singleton
  end
end
