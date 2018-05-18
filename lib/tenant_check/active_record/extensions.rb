# frozen_string_literal: true

require 'active_support/concern'

module TenantCheck
  module ActiveRecord
    module TenantMethodExtension
      extend ActiveSupport::Concern

      included do
        attr_accessor :_tenant_check_safe
      end
    end

    module TenantSafetyCheck
      class << self
        def safe_preloading
          Thread.current[:tenant_check_safe_preloading]
        end

        def safe_preloading=(value)
          Thread.current[:tenant_check_safe_preloading] = value
        end

        def safe_preload(safe)
          prev, self.safe_preloading = safe_preloading, true if safe # rubocop:disable Style/ParallelAssignment
          yield
        ensure
          self.safe_preloading = prev if safe
        end
      end

      private

      def check_tenant_safety(sql_descpription = nil)
        return true if TenantSafetyCheck.safe_preloading || klass.name == ::TenantCheck.tenant_class_name
        return true if respond_to?(:proxy_association) && proxy_association.owner._tenant_check_safe
        unless tenant_safe_where_clause?(where_clause)
          c = caller
          lines = c.join("\n")
          unless ::TenantCheck.safe_caller_patterns.any? { |reg| reg.match?(lines) }
            ::TenantCheck.add_notification ::TenantCheck::Notification.new(c, klass, sql_descpription || to_sql)
            return false
          end
        end
        true
      end

      def tenant_safe_where_clause?(clause)
        predicates = clause.send(:predicates)
        equalities = predicates.grep(Arel::Nodes::Equality)
        equalities.any? do |node|
          attribute = node.left
          return true if ::TenantCheck.tenant_associations[attribute.relation.name]&.member?(attribute.name)
        end
      end
    end

    module CollectionProxyExtension
      include TenantSafetyCheck

      def load_target
        return super unless ::TenantCheck.enable_and_started?
        return super if loaded?

        safe = check_tenant_safety
        result = TenantSafetyCheck.safe_preload(safe) do
          super
        end
        if safe
          Array(target).each do |record|
            record._tenant_check_safe = true
          end
        end
        result
      end
    end

    module RelationExtension
      include TenantSafetyCheck

      def pluck(*column_names)
        return super unless ::TenantCheck.enable_and_started?
        return super if has_include?(column_names.first)
        check_tenant_safety('pluck')
        super
      end

      private

      def exec_queries(&block)
        return super unless ::TenantCheck.enable_and_started?

        safe = check_tenant_safety

        result = TenantSafetyCheck.safe_preload(safe) do
          super
        end

        if safe
          @records.each do |record|
            record._tenant_check_safe = true
          end
        end

        result
      end
    end

    class << self
      def apply_patch
        ::ActiveRecord::Base.include TenantMethodExtension
        ::ActiveRecord::Relation.prepend RelationExtension
        ::ActiveRecord::Associations::CollectionProxy.prepend CollectionProxyExtension
      end
    end
  end
end
