module RequestsSpecHelper
  DEFAULT_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

  def request_headers
    {
      "User-Agent" => DEFAULT_USER_AGENT,
      "HTTP_USER_AGENT" => DEFAULT_USER_AGENT
    }
  end

  def configure_request_host!(host: "example.com")
    Rails.application.config.hosts.clear
    host! host
  end
end

RSpec.configure do |config|
  config.include RequestsSpecHelper, type: :request
end
