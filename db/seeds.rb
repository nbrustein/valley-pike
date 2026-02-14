# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

DEFAULT_PASSWORD = "password".freeze
EMAIL_DOMAIN = "example.com".freeze

def upsert_organization!(name:, abbreviation:, require_vetted_drivers:)
  organization = Organization.find_or_initialize_by(abbreviation:)
  organization.name = name
  organization.require_vetted_drivers = require_vetted_drivers
  organization.save!
  organization
end

def upsert_user!(email:)
  user = User.find_or_initialize_by(email:)
  user.email = email
  user.save!

  identity = Identity.find_or_initialize_by(kind: "password", email:)
  identity.user = user
  identity.password = DEFAULT_PASSWORD
  identity.password_confirmation = DEFAULT_PASSWORD
  identity.skip_password_validation = true
  identity.skip_password_strength_validation = true
  identity.save!

  user
end

def upsert_user_role!(user:, role:, organization:)
  UserRole.find_or_create_by!(user:, role:, organization:)
end

organizations = {
  "udo" => upsert_organization!(
    name: "Unvetted Driver Org",
    abbreviation: "UDO",
    require_vetted_drivers: false
  ),
  "vdo" => upsert_organization!(
    name: "Vetted Driver Org",
    abbreviation: "VDO",
    require_vetted_drivers: true
  )
}

user_definitions = [
  {
    email: "dev.deverson@#{EMAIL_DOMAIN}",
    roles: [ [ UserRole::DEVELOPER, nil ], [ UserRole::VANITA_ADMIN, nil ], [ UserRole::ORG_ADMIN, nil ] ]
  },
  {
    email: "vanita.leader@#{EMAIL_DOMAIN}",
    roles: [ [ UserRole::VANITA_ADMIN, nil ], [ UserRole::DRIVER, nil ], [ UserRole::ORG_ADMIN, nil ] ]
  },
  {
    email: "vanita.driverless@#{EMAIL_DOMAIN}",
    roles: [ [ UserRole::VANITA_ADMIN, nil ], [ UserRole::ORG_ADMIN, nil ] ]
  },
  {
    email: "udo.admin@#{EMAIL_DOMAIN}",
    roles: [ [ UserRole::ORG_ADMIN, organizations.fetch("udo") ] ]
  },
  {
    email: "vdo.admin@#{EMAIL_DOMAIN}",
    roles: [ [ UserRole::ORG_ADMIN, organizations.fetch("vdo") ] ]
  },
  {
    email: "unvetted.driver.1@#{EMAIL_DOMAIN}",
    roles: [ [ UserRole::DRIVER, nil ] ]
  },
  {
    email: "vdo.vetted.driver.1@#{EMAIL_DOMAIN}",
    roles: [ [ UserRole::DRIVER, organizations.fetch("vdo") ] ]
  },
  {
    email: "unvetted.driver.2@#{EMAIL_DOMAIN}",
    roles: [ [ UserRole::DRIVER, nil ] ]
  },
  {
    email: "vdo.vetted.driver.2@#{EMAIL_DOMAIN}",
    roles: [ [ UserRole::DRIVER, organizations.fetch("vdo") ] ]
  }
]

user_definitions.each do |user_definition|
  user = upsert_user!(email: user_definition.fetch(:email))

  user_definition.fetch(:roles).each do |role, organization|
    upsert_user_role!(user:, role:, organization:)
  end
end
