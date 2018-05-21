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
        def internal_force_safe_scope?
          Thread.current[:tenant_check_internal_force_safe_scope]
        end

        def internal_force_safe_scope=(value)
          Thread.current[:tenant_check_internal_force_safe_scope] = value
        end

        def internal_force_safe(safe)
          # rubocop:disable Style/ParallelAssignment
          prev, self.internal_force_safe_scope = internal_force_safe_scope?, true if safe
          # rubocop:enable Style/ParallelAssignment
          yield
        ensure
          self.internal_force_safe_scope = prev if safe
        end
      end

      private

      def check_tenant_safety(sql_descpription = nil)
        return true if _tenant_safe_mark? || TenantSafetyCheck.internal_force_safe_scope?
        return true if klass.name == ::TenantCheck.tenant_class_name
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

    module CollectionProxyCheck
      include TenantSafetyCheck

      def load_target
        return super unless ::TenantCheck.enable_and_started?
        return super if loaded?

        safe = check_tenant_safety
        # preloading is safe if the relation is safe
        result = TenantSafetyCheck.internal_force_safe(safe) do
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

    module BaseClassMethods
      def mark_as_tenant_safe
        relation = all
        relation.mark_as_tenant_safe
        relation
      end
    end

    module RelationMethods
      def mark_as_tenant_safe
        @_tenant_safe_mark = true
        self
      end

      def _tenant_safe_mark?
        @_tenant_safe_mark
      end
    end

    module RelationCheck
      include TenantSafetyCheck

      def calculate(operation, column_name)
        return super unless ::TenantCheck.enable_and_started?
        TenantSafetyCheck.internal_force_safe(_tenant_safe_mark?) do
          # FIXME: Calling has_include? is highly implementation dependent. It subject to change by rails versions.
          return super if has_include?(column_name)
          check_tenant_safety(operation.to_s)
          super
        end
      end

      def pluck(*column_names)
        return super unless ::TenantCheck.enable_and_started?
        TenantSafetyCheck.internal_force_safe(_tenant_safe_mark?) do
          # FIXME: Calling has_include? is highly implementation dependent. It subject to change by rails versions.
          return super if has_include?(column_names.first)
          check_tenant_safety('pluck')
          super
        end
      end

      private

      def exec_queries(&block)
        return super unless ::TenantCheck.enable_and_started?

        safe = check_tenant_safety

        # preloading is safe if the relation is safe
        result = TenantSafetyCheck.internal_force_safe(safe) do
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
        ::ActiveRecord::Base.extend ::TenantCheck::ActiveRecord::BaseClassMethods
        ::ActiveRecord::Relation.prepend ::TenantCheck::ActiveRecord::RelationMethods
      end

      def apply_check_patch
        ::ActiveRecord::Base.include ::TenantCheck::ActiveRecord::TenantMethodExtension
        ::ActiveRecord::Relation.prepend ::TenantCheck::ActiveRecord::RelationCheck
        ::ActiveRecord::Associations::CollectionProxy.prepend ::TenantCheck::ActiveRecord::CollectionProxyCheck
      end
    end
  end
end
