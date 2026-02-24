FactoryBot.define do
  factory :organization do
    sequence(:name) {|n| "Organization #{n}" }
    sequence(:abbreviation) {|n| "ORG#{n}" }
    required_qualifications { [] }
  end
end
