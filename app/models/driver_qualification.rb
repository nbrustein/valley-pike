class DriverQualification < ApplicationRecord
  QUALIFICATION_CWS_VETTED = "cws_vetted"
  QUALIFICATIONS = [ QUALIFICATION_CWS_VETTED ].to_set.freeze

  belongs_to :user

  validates :qualification, inclusion: {in: QUALIFICATIONS}
  validates :qualification, uniqueness: {scope: :user_id}
end
