# frozen_string_literal: true

require "active_record"
require "delayed_job"

ActiveSupport.on_load(:active_record) do
  require "delayed/backend/active_record"

  Delayed::Worker.backend = :active_record
end
