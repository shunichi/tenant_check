# frozen_string_literal: true

require 'tenant_check/stack_trace_fliter'

module TenantCheck
  class Notification
    attr_reader :callers, :filtered_callers, :base_class, :sql

    def initialize(callers, base_class, sql)
      @callers = callers
      @filtered_callers = StackTraceFilter.filter_in_project(callers)
      @base_class = base_class
      @sql = sql
    end

    def filtered_callers_or_callers
      filtered_callers.empty? ? callers : filtered_callers
    end

    def eql?(other)
      base_class == other.base_class && callers == other.callers
    end

    def hash
      [base_class, callers].hash
    end

    def message
      <<~EOS
        >>> Query without tenant condition detected!
        class: #{base_class.to_s}
        sql: #{sql}
        stacktrace:
        #{filtered_callers_or_callers.join("\n")}
        
      EOS
    end
  end
end
