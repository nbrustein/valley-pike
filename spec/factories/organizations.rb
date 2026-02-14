FactoryBot.define do
  factory :organization do
    sequence(:name) {|n| "Organization #{n}" }
    sequence(:abbreviation) {|n| "ORG#{n}" }
    require_vetted_drivers { false }
  end
end
