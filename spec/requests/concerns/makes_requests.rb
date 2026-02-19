module MakesRequests
  DEFAULT_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

  def request_headers
    {
      "User-Agent" => DEFAULT_USER_AGENT,
      "HTTP_USER_AGENT" => DEFAULT_USER_AGENT,
    }
  end

  def configure_request_host!(host: "example.com")
    Rails.application.config.hosts.clear
    host! host
  end

  def raise_exceptions_for_request!
    Rails.application.env_config["action_dispatch.show_exceptions"] = false
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = true
  end

  def raise_exception_from_response!
    exception = response.request.env["action_dispatch.exception"]
    exception ||= response.request.env["action_dispatch.exception_wrapper"]&.exception
    raise exception if exception

    return if response.status < 500

    log_snippet = last_test_log_exception_snippet
    return raise "Request returned #{response.status} without exception. Log snippet:\n#{log_snippet}" if log_snippet

    text_body = ActionView::Base.full_sanitizer.sanitize(response.body.to_s)
    compact_text = text_body.gsub(/\s+/, " ").strip
    exception_with_context = compact_text[/([A-Z]\w+(::\w+)+)\s+in\s+[A-Za-z0-9_:##]+/, 0]
    exception_class = compact_text[/[A-Z]\w+(::\w+)+/]
    error_line = exception_with_context
    error_line ||= if exception_class
      compact_text[/#{Regexp.escape(exception_class)}.{0,160}/]
    end
    error_line ||= compact_text[0, 300]
    raise "Request returned #{response.status} without exception. Error: #{error_line.inspect}"
  end

  def last_test_log_exception_snippet
    log_path = Rails.root.join("log/test.log")
    return nil unless File.exist?(log_path)

    lines = File.read(log_path).split("\n")
    start_index = lines.rindex {|line| line.match?(/(Exception|Error|ActionController::|ActionView::)/) }
    return nil unless start_index

    lines[start_index, 20].join("\n")
  end

  def assert_success
    raise_exceptions_for_request!
    yield
    raise_exception_from_response!
    expect(response).to have_http_status(:ok)
    response
  end

  def assert_redirect(to:)
    raise_exceptions_for_request!
    yield
    raise_exception_from_response!
    expect(response).to redirect_to(to), -> {
      "Expected redirect to #{to}, got status #{response.status}, location #{response.location.inspect}"
    }
    response
  end
end
