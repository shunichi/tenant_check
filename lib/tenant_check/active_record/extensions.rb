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
          prev, self.safe_preloading = safe_preloading, true if safe
          yield
        ensure
          self.safe_preloading = prev if safe
        end
      end

      private
      
      def check_tenant_safety
        return true if TenantSafetyCheck.safe_preloading || klass.name == ::TenantCheck.tenant_class_name
        return true if respond_to?(:proxy_association) && proxy_association.owner._tenant_check_safe
        unless tenant_safe_where_clause?(where_clause)
          c = caller 
          lines = c.join("\n")
          unless ::TenantCheck.safe_caller_patterns.any? { |reg| reg.match?(lines) }
            ::TenantCheck.add_notification ::TenantCheck::Notification.new(c, klass, to_sql)
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
          if ::TenantCheck.tenant_associations[attribute.relation.name]&.member?(attribute.name)
            return true
          end
        end
      end
    end

    module CollectionProxyExtension
      include TenantSafetyCheck

      def load_target
        return super unless ::TenantCheck.started?
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

      private 

      def exec_queries(&block)
        return super unless ::TenantCheck.started?

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

    module ActiveRecordExtension
      def find_by_sql(sql, binds = [], preparable: nil, &block)
        puts '************************* find_by_sql'
        puts caller
        puts '************************* sql'
        pp sql
        puts '************************* binds'
        pp binds
        puts '************************* to_sql'
        puts connection.to_sql(sql, binds)
        puts '************************* dump_arel'
        dump_arel(sql)
        super
      end

      def dump_arel(arel, depth = 0)
        case arel
        when Array
          arel.each do |node|
            dump_arel(node, depth + 1)
          end
        when ::Arel::SelectManager
          indent_puts(depth, '[SelectManager]')
          dump_arel(arel.ast, depth + 1)
          pp arel
        when ::Arel::Nodes::SelectStatement
          indent_puts(depth, '[SelectStatement]')
          dump_arel(arel.cores, depth + 1)
        when ::Arel::Nodes::SelectCore
          indent_puts(depth, '[SelectCore]')
          indent_puts(depth + 1, 'projections=')
          dump_arel(arel.projections, depth + 1)
          indent_puts(depth + 1, 'join_source=')
          dump_arel(arel.source, depth + 2)
          indent_puts(depth + 1, 'wheres=')
          dump_arel(arel.wheres, depth + 1)
        when ::Arel::Nodes::Node
          indent_puts(depth, "[#{arel.class.to_s}]")
        when ::Arel::Attributes::Attribute
          indent_puts(depth, "[#{arel.class.to_s}]")
        end

      end

      def indent_puts(depth, str)
        puts "  " * depth + str
      end
    end

    class << self
      def enable
        ::ActiveRecord::Base.include TenantMethodExtension
        ::ActiveRecord::Relation.prepend RelationExtension
        ::ActiveRecord::Associations::CollectionProxy.prepend CollectionProxyExtension
      end
    end
  end
end