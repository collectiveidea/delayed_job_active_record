class ColumnsNotNull < ActiveRecord::Migration<%= migration_version %>
  def change
    change_column_null :delayed_jobs, :run_at, false
    change_column_null :delayed_jobs, :queue, false
    change_column_null :delayed_jobs, :created_at, false
    change_column_null :delayed_jobs, :updated_at, false
  end
end
