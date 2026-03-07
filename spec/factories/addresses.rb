FactoryBot.define do
  factory :address do
    name { "Main Office" }
    street_address { "123 Main St" }
    city { "Springfield" }
    state { "VA" }
    zip { "22150" }
    country { "US" }
  end
end
