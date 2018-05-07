# frozen_string_literal: true

require 'action_dispatch'

module TenantCheck
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      TenantCheck.start
      status, headers, response = @app.call(env)
      if TenantCheck.notification? && html_headers?(status, headers) && (body = response_body(response))
        TenantCheck.output_notifications
        body = append_to_html_body(body, footer_html)
        content_length = body.bytesize.to_s
        headers['Content-Length'] = content_length
        # maintains compatibility with other middlewares
        if defined?(ActionDispatch::Response::RackBody) && response.is_a?(ActionDispatch::Response::RackBody)
          ActionDispatch::Response.new(status, headers, [body]).to_a
        else
          [status, headers, [body]]
        end
      else
        [status, headers, response]
      end
    ensure
      TenantCheck.end
    end

    private

    def append_to_html_body(body, content)
      body = body.dup
      if body.include?('</body>')
        position = body.rindex('</body>')
        body.insert(position, content)
      else
        body << content
      end
    end

    def footer_html
      <<~EOS
        <div ondblclick="this.parentNode.removeChild(this);" style="position: fixed; right: 0; bottom: 0; z-index:9999; font-size: 16px; padding: 8px 32px 8px 8px; background-color: rgb(224, 104, 15); color: white; border-style: solid; border-color: rgb(140, 69, 15); border-width: 2px 0 0 2px; border-radius: 8px 0 0 0; cursor: pointer;">
          <div onclick='this.parentNode.remove()' style='position:absolute; right: 10px; top: 6px; font-weight: bold; color: white;'>&times;</div>
          #{TenantCheck.notifications.size} tenant unsafe queries detected!
        </div>
      EOS
    end

    def file?(headers)
      headers['Content-Transfer-Encoding'] == 'binary' || headers['Content-Disposition']
    end

    def html_headers?(status, headers)
      status == 200 &&
        headers['Content-Type'] &&
        headers['Content-Type'].include?('text/html') &&
        !file?(headers)
    end

    def response_body(response)
      strings = []
      response.each { |s| strings << s.to_s }
      strings.join
    end
  end
end
