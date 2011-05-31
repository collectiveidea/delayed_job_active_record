require 'delayed_job'
require 'active_record'

require 'delayed/backend/active_record'

Delayed::Worker.backend = :active_record