Rack::Attack.cache.store = Rails.cache

class Rack::Attack
  LOGIN_PATH = "/identities/sign_in"
  LOGIN_PERIOD = 10.minutes
  LOGIN_LIMIT_PER_IP = 10
  LOGIN_LIMIT_PER_EMAIL = 5

  def self.login_request?(request)
    request.post? && request.path == LOGIN_PATH
  end

  def self.normalized_login_email(request)
    email = request.params.dig("identity", "email").to_s

    email.strip.downcase.presence
  end

  throttle("login/ip", limit: LOGIN_LIMIT_PER_IP, period: LOGIN_PERIOD) do |request|
    request.ip if login_request?(request)
  end

  throttle("login/email", limit: LOGIN_LIMIT_PER_EMAIL, period: LOGIN_PERIOD) do |request|
    normalized_login_email(request) if login_request?(request)
  end

  self.throttled_responder = lambda do |_request|
    [ 429, {"Content-Type" => "text/plain"}, [ "Rate limit exceeded. Try again later.\n" ] ]
  end
end
