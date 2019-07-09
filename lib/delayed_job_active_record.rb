# frozen_string_literal: true

require "delayed_job"

if defined?(Rails::Railtie)
  require "delayed/backend/active_record/railtie"
else
  require "active_record"
  require "delayed/backend/active_record"

  Delayed::Worker.backend = :active_record
end
