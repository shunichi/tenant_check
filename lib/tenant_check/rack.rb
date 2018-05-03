# frozen_string_literal: true

module TenantCheck
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      TenantCheck.start
      result = @app.call(env)
      TenantCheck.output_notifications
      result
    ensure
      TenantCheck.end
    end
  end
end
