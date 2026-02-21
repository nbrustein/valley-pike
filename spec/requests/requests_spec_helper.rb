require "requests/concerns/makes_requests"
require "requests/concerns/has_forms"

require "capybara/rspec"

RSpec.configure do |config|
  config.include MakesRequests, type: :request
  config.include HasForms, type: :request
  config.include Capybara::RSpecMatchers, type: :request
end
