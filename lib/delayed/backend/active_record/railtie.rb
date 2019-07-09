# frozen_string_literal: true

module Delayed
  module Backend
    module ActiveRecord
      class Railtie < ::Rails::Railtie
        config.after_initialize do
          require "delayed/backend/active_record"
          Delayed::Worker.backend = :active_record
        end
      end
    end
  end
end
