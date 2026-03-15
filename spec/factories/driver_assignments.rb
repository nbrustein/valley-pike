FactoryBot.define do
  factory :driver_assignment do
    association :ride_request
    association :driver, factory: :user
  end
end
