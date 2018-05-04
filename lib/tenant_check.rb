# frozen_string_literal: true

require "tenant_check/version"
require "active_support/lazy_load_hooks"
require 'set'
require 'logger'

module TenantCheck
  autoload :Notification, 'tenant_check/notification'
  autoload :Rack, 'tenant_check/rack'

  class << self
    def enable
      @enable
    end

    def enable=(value)
      @enable = value
      if value && !@patched
        @patched = true
        ActiveSupport.on_load(:active_record) do
          require 'tenant_check/active_record/extensions'
          ::TenantCheck::ActiveRecord.apply_patch

          if defined? Rails
            ::Rails.configuration.middleware.use TenantCheck::Rack
          end
        end
      end
    end
    
    def tenant_class=(klass)
      if ::TenantCheck.tenant_class_name != nil && ::TenantCheck.tenant_class_name != klass.name
        raise 'TenantCheck.tenant_class= must be called only once'
      end
      ::TenantCheck.tenant_class_name = klass.name

      klass.reflections.each do |name, reflection|
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
        /^.*devise.*`serialize_from_session'.*$/,
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
      enable && started?
    end

    def notifications
      Thread.current[:tenant_check_notifications]
    end

    def add_notification(notification)
      notifications.add(notification) if started?
    end

    def output_notifications
      notifications.each do |notification|
        logger.warn(notification.message)
      end
    end

    def logger
      @logger ||= defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    end
  end
end
