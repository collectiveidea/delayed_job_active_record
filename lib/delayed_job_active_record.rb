require "active_record"
require "delayed_job"
require "delayed/backend/active_record"
require "delayed/backend/alternate_active_record"

Delayed::Worker.backend = Delayed::Backend::AlternateActiveRecord::Job
