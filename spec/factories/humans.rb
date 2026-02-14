FactoryBot.define do
  factory :human do
    sequence(:full_name) {|n| "User #{n}" }
    sequence(:sortable_name) {|n| "User #{n}" }
    sequence(:phone) {|n| "555-01#{format('%02d', n)}" }
  end
end
