# frozen_string_literal: true

require "active_record"
require "delayed_job"
require "delayed/backend/active_record"

ActiveSupport.on_load(:active_record) do
  Delayed::Worker.backend = :active_record
end
