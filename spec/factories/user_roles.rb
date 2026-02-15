FactoryBot.define do
  factory :user_role do
    user
    role { UserRole::DRIVER }
    organization { nil }
  end
end
