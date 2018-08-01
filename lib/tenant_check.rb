# frozen_string_literal: true

require 'tenant_check/version'
require 'active_support/lazy_load_hooks'
require 'set'
require 'logger'

module TenantCheck
  autoload :Notification, 'tenant_check/notification'
  autoload :Rack, 'tenant_check/rack'

  class << self
    attr_reader :enable
    attr_writer :logger
    attr_accessor :raise_error

    def enable=(value)
      @enable = value

      return if @patched || !value
      @patched = true
      ActiveSupport.on_load(:active_record) do
        require 'tenant_check/active_record/extensions'
        ::TenantCheck::ActiveRecord.apply_check_patch
        ::Rails.configuration.middleware.use TenantCheck::Rack if defined? Rails
      end
    end

    def tenant_class=(klass)
      if ::TenantCheck.tenant_class_name != nil && ::TenantCheck.tenant_class_name != klass.name
        raise 'TenantCheck.tenant_class= must be called only once'
      end
      ::TenantCheck.tenant_class_name = klass.name

      klass.reflections.each do |_, reflection|
        case reflection
        when ::ActiveRecord::Reflection::HasManyReflection, ::ActiveRecord::Reflection::HasOneReflection
          ::TenantCheck.add_association(reflection.klass.arel_table.name, reflection.foreign_key)
        end
      end
    end

    attr_accessor :tenant_class_name
    attr_writer :tenant_associations, :safe_caller_patterns

    def tenant_associations
      @tenant_associations ||= {}
    end

    def add_association(table, foreign_key)
      tenant_associations[table] ||= Set.new
      tenant_associations[table].add(foreign_key)
    end

    def default_safe_caller_patterns
      [
        /^.*devise.*`serialize_from_(session|cookie)'.*$/,
      ]
    end

    def safe_caller_patterns
      @safe_caller_patterns ||= default_safe_caller_patterns
    end

    def start
      Thread.current[:tenant_check_start] = true
      Thread.current[:tenant_check_notifications] = Set.new
    end

    def end
      Thread.current[:tenant_check_start] = nil
      Thread.current[:tenant_check_notifications] = nil
    end

    def started?
      Thread.current[:tenant_check_start]
    end

    def enable_and_started?
      enable && started? && !temporally_disabled?
    end

    def temporally_disabled?
      Thread.current[:tenant_check_temporally_disabled]
    end

    def temporally_disabled=(value)
      Thread.current[:tenant_check_temporally_disabled] = value
    end

    def ignored
      prev, self.temporally_disabled = temporally_disabled?, true # rubocop:disable Style/ParallelAssignment
      yield
    ensure
      self.temporally_disabled = prev
    end

    def notifications
      Thread.current[:tenant_check_notifications]
    end

    def add_notification(notification)
      notifications.add(notification) if started?
    end

    def notification?
      !notifications.empty?
    end

    def output_notifications
      notifications.each do |notification|
        logger.warn(notification.message)
      end
      if raise_error && (notification = notifications.first) # rubocop:disable Style/GuardClause
        raise UnsafeQueryError, notification.message
      end
    end

    def logger
      @logger ||= defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    end
  end

  class UnsafeQueryError < ::StandardError; end
end

ActiveSupport.on_load(:active_record) do
  require 'tenant_check/active_record/extensions'
  ::TenantCheck::ActiveRecord.apply_patch
end
