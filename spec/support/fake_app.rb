# frozen_string_literal: true

module Support
  class FakeApp
    attr_reader :body

    def initialize(body, &block)
      @body = body
      @block = block
    end

    def call(_env)
      @block&.call
      [200, headers, [body]]
    end

    def headers
      { 'Content-Type' => 'text/html' }
    end
  end
end
