class UserRole < ApplicationRecord
  # developers can do everything
  DEVELOPER = "developer"

  # vanita admins can manage users
  # vanita admins can do anything that org admins can do
  VANITA_ADMIN = "vanita_admin"

  # org admins manage ride requesters in their organization and also act as
  # ride requesters themselves
  ORG_ADMIN = "org_admin"

  # ride requesters can manage ride requests
  RIDE_REQUESTER = "ride_requester"

  # drivers can edit some things in their own profiles
  # drivers can view ride requests they have permissions for
  # drivers can accept ride requests
  DRIVER = "driver"

  ROLES = [ DEVELOPER, VANITA_ADMIN, ORG_ADMIN, RIDE_REQUESTER, DRIVER ].to_set.freeze

  belongs_to :user
  belongs_to :organization, optional: true

  validates :role, inclusion: {in: ROLES}
  validates :organization, presence: true, if: -> { role.in?([ ORG_ADMIN, RIDE_REQUESTER ]) }
  validates :organization, absence: true, if: -> { role.in?([ DEVELOPER, VANITA_ADMIN ]) }

  def has_role_permissions?(target_role)
    # developers can do anything
    return true if role == DEVELOPER

    # vanita admins and do everything that org admins can do
    return true if role == VANITA_ADMIN && target_role == ORG_ADMIN

    role == target_role
  end

  def pill_label
    case role
    when DEVELOPER
      "dev"
    when VANITA_ADMIN
      "vanita"
    when ORG_ADMIN
      return "#{organization.abbreviation.downcase} admin" if organization.present?

      "admin"
    when RIDE_REQUESTER
      return "#{organization.abbreviation.downcase} ride requester" if organization.present?

      "ride requester"
    when DRIVER
      return "#{organization.abbreviation.downcase} driver" if organization.present?

      "driver"
    else
      role
    end
  end
end
