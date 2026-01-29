# frozen_string_literal: true

# Middleware to redirect old domain to new primary domain
class DomainRedirect
  OLD_HOST = "cam-postal.gotabs.net"
  NEW_HOST = "cambo-postal.com"

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    if request.host == OLD_HOST
      new_url = "https://#{NEW_HOST}#{request.fullpath}"
      [ 301, { "Location" => new_url, "Content-Type" => "text/html" }, [ "Redirecting to #{new_url}" ] ]
    else
      @app.call(env)
    end
  end
end
