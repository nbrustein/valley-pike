# frozen_string_literal: true

FactoryBot.define do
  sequence(:identity_email) { |n| "user#{n}@example.com" }

  factory :identity do
    user
    kind { "password" }
    email { generate(:identity_email) }
    password { "Str0ngPassw0rd!" }
    password_confirmation { password }

    trait :magic_link do
      kind { "magic_link" }
      password { nil }
      password_confirmation { nil }
    end
  end
end
