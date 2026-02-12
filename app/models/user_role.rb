class UserRole < ApplicationRecord
  DEVELOPER = "developer"
  VANITA_ADMIN = "vanita_admin"
  ORG_ADMIN = "org_admin"
  DRIVER = "driver"

  ROLES = [ DEVELOPER, VANITA_ADMIN, ORG_ADMIN, DRIVER ].freeze

  belongs_to :user
  belongs_to :organization, optional: true

  validates :role, inclusion: {in: ROLES}
end
