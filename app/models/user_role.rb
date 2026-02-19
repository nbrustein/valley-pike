class UserRole < ApplicationRecord
  # developers can do everything
  DEVELOPER = "developer"

  # vanita admins can manage users
  # vanita admins can do anything that org admins can do
  VANITA_ADMIN = "vanita_admin"

  # vanita viewers can view all users, but cannot edit them
  # vanita viewers can view all ride requests, but cannot edit them
  VANITA_VIEWER = "vanita_viewer"

  # org admins manage ride requesters in their organization and also act as
  # ride requesters themselves
  ORG_ADMIN = "org_admin"

  # ride requesters can manage ride requests
  RIDE_REQUESTER = "ride_requester"

  # drivers can edit some things in their own profiles
  # drivers can view ride requests they have permissions for
  # drivers can accept ride requests
  DRIVER = "driver"

  ROLES = [ DEVELOPER, VANITA_ADMIN, VANITA_VIEWER, ORG_ADMIN, RIDE_REQUESTER, DRIVER ].to_set.freeze

  belongs_to :user
  belongs_to :organization, optional: true

  validates :role, inclusion: {in: ROLES}
  validates :organization, presence: true, if: -> { role.in?([ ORG_ADMIN, RIDE_REQUESTER ]) }
  validates :organization, absence: true, if: -> { role.in?([ DEVELOPER, VANITA_ADMIN, VANITA_VIEWER ]) }

  def self.has_role_permissions?(role, target_role)
    # only drivers act as drivers. Not even developers can be drivers unless
    # they also have that role explicitly
    return role == DRIVER if target_role == DRIVER

    # developers can do anything
    return true if role == DEVELOPER

    # vanita admins and do everything that org admins can do or vanita viewers can do
    return true if role == VANITA_ADMIN && has_role_permissions?(ORG_ADMIN, target_role)
    return true if role == VANITA_ADMIN && has_role_permissions?(VANITA_VIEWER, target_role)

    # org admins can do everything that ride requesters can do
    return true if role == ORG_ADMIN && has_role_permissions?(RIDE_REQUESTER, target_role)

    role == target_role
  end

  def has_role_permissions?(target_role)
    self.class.has_role_permissions?(role, target_role)
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
