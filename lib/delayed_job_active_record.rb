require "delayed_job"

if defined?(Rails)
  require "delayed/backend/active_record/railtie"
else
  require "active_record"
  require "delayed/backend/active_record"

  Delayed::Worker.backend = :active_record
end
