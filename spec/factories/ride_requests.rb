FactoryBot.define do
  factory :ride_request, class: "RideRequest::Published" do
    association :organization
    association :requester, factory: :user
    association :pick_up_address, factory: :address
    draft { false }
    desired_driver_gender { "none" }
    contact_full_name { "Jane Doe" }
    date { Date.today + 7 }
    short_description { "Ride to appointment" }
    ride_description_public { "Please arrive 10 minutes early." }
  end

  factory :draft_ride_request, class: "RideRequest::Draft" do
    association :organization
    association :requester, factory: :user
    association :pick_up_address, factory: :address
    draft { true }
    desired_driver_gender { "none" }
    contact_full_name { "Jane Doe" }
    date { Date.today + 7 }
    short_description { "Ride to appointment" }
    ride_description_public { "Please arrive 10 minutes early." }

    trait :unpublishable do
      pick_up_address { nil }
      contact_full_name { nil }
      date { nil }
      short_description { nil }
      ride_description_public { nil }
    end
  end
end
