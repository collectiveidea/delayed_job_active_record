module Delayed
  module Backend
    module ActiveRecord
      class Railtie < ::Rails::Railtie
        initializer 'delayed_job_active_record' do |_app|
          ActiveSupport.on_load(:active_record) do
            require "delayed/backend/active_record"
            Delayed::Worker.backend = :active_record
          end
        end
      end
    end
  end
end
