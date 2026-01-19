# frozen_string_literal: true

require "active_record/version"
require "active_support/lazy_load_hooks"
require "delayed/backend/active_record/configuration"

ActiveSupport.on_load(:active_record) do
  require "delayed/backend/active_record/job"
end
