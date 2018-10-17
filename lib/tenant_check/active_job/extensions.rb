# frozen_string_literal: true

require 'active_support/concern'

module TenantCheck
  module ActiveJob
    module BaseMethods
      def deserialize_arguments(*args)
        TenantCheck::ActiveRecord::TenantSafetyCheck.internal_force_safe(true) do
          super
        end
      end
    end

    class << self
      def apply_patch
        ::ActiveJob::Base.include ::TenantCheck::ActiveJob::BaseMethods
      end
    end
  end
end
