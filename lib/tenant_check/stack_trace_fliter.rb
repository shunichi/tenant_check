# frozen_string_literal: true

module TenantCheck
  module StackTraceFilter
    class << self
      def filter_in_project(paths)
        app_root = defined?(Rails) ? Rails.root.to_s : Dir.pwd
        bundler_path = Bundler.bundle_path.to_s
        paths.select do |path|
          path.include?(app_root) && !path.include?(bundler_path)
        end
      end
    end
  end
end