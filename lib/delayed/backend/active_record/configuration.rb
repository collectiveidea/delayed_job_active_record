# frozen_string_literal: true

module Delayed
  module Backend
    module ActiveRecord
      class Configuration
        attr_reader :reserve_sql_strategy

        def initialize
          self.reserve_sql_strategy = :optimized_sql
        end

        def reserve_sql_strategy=(val)
          if !(val == :optimized_sql || val == :default_sql)
            raise ArgumentError, "allowed values are :optimized_sql or :default_sql"
          end

          @reserve_sql_strategy = val
        end
      end

      def self.configuration
        @configuration ||= Configuration.new
      end

      def self.configure
        yield(configuration)
      end
    end
  end
end
