class RideRequest < ApplicationRecord
  DESIRED_DRIVER_GENDERS = %w[female female_accompaniment none].freeze

  belongs_to :organization
  belongs_to :requester, class_name: "User"
  belongs_to :pick_up_address, class_name: "Address", optional: true
  belongs_to :destination_address, class_name: "Address", optional: true
  has_many :driver_assignments
  has_many :drivers, through: :driver_assignments, source: :driver

  scope :published, -> { where(draft: false) }

  validates :desired_driver_gender, inclusion: {in: DESIRED_DRIVER_GENDERS}
end
