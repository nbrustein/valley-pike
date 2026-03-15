FactoryBot.define do
  factory :driver_qualification do
    association :user
    qualification { DriverQualification::QUALIFICATION_CWS_VETTED }
  end
end
