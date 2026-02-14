FactoryBot.define do
  factory :user do
    sequence(:email) {|n| "user#{n}@example.com" }

    after(:build) do |user|
      user.human ||= build(:human, user:)
    end

    trait :with_identity do
      transient do
        identity_kind { "password" }
        identity_email { nil }
      end

      after(:create) do |user, evaluator|
        attrs = {user:}
        attrs[:email] = evaluator.identity_email if evaluator.identity_email

        if evaluator.identity_kind == "magic_link"
          create(:identity, :magic_link, **attrs)
        else
          create(:identity, **attrs.merge(kind: evaluator.identity_kind))
        end
      end
    end
  end
end
