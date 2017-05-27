module Delayed
  module Backend
    module ActiveRecord
      class Engine < ::Rails::Engine
        paths['app/models'] << 'lib'

        initializer 'delayed_job_active_record' do |_app|
          ActiveSupport.on_load(:active_record) do
            Delayed::Worker.backend = :active_record
          end
        end
      end
    end
  end
end
