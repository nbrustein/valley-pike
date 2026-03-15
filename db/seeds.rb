# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

return unless Rails.env.development?

DEFAULT_PASSWORD = "password".freeze
EMAIL_DOMAIN = "example.com".freeze

def upsert_seed_executor!(email:)
  user = User.find_or_initialize_by(email:)
  if user.human.nil?
    user.build_human(
      full_name: "seed executor",
      preferred_name: "seed",
      phone: "555-0000"
    )
  end
  user.save! if user.new_record? || user.changed? || user.human&.changed?
  user
end

def default_preferred_name(full_name)
  full_name.split.first
end

def upsert_organization!(name:, abbreviation:, required_qualifications:)
  organization = Organization.find_or_initialize_by(abbreviation:)
  organization.name = name
  organization.required_qualifications = required_qualifications
  organization.save!
  organization
end

organizations = {
  "udo" => upsert_organization!(
    name: "Unvetted Driver Org",
    abbreviation: "UDO",
    required_qualifications: []
  ),
  "vdo" => upsert_organization!(
    name: "Vetted Driver Org",
    abbreviation: "VDO",
    required_qualifications: [ DriverQualification::QUALIFICATION_CWS_VETTED ]
  ),
}

user_definitions = [
  {
    email: "dev@#{EMAIL_DOMAIN}",
    full_name: "dev deverson",
    phone: "555-0101",
    user_roles: [ {role: UserRole::DEVELOPER, organization_id: nil} ],
  },
  {
    email: "vanita.leader@#{EMAIL_DOMAIN}",
    full_name: "vanita leader",
    phone: "555-0102",
    user_roles: [
      {role: UserRole::VANITA_ADMIN, organization_id: nil},
      {role: UserRole::DRIVER, organization_id: nil},
    ],
  },
  {
    email: "vanita.driverless@#{EMAIL_DOMAIN}",
    full_name: "vanita driverless",
    phone: "555-0103",
    user_roles: [ {role: UserRole::VANITA_ADMIN, organization_id: nil} ],
  },
  {
    email: "vanita.viewer@#{EMAIL_DOMAIN}",
    full_name: "vanita viewer",
    phone: "555-0112",
    user_roles: [ {role: UserRole::VANITA_VIEWER, organization_id: nil} ],
  },
  {
    email: "udo.admin@#{EMAIL_DOMAIN}",
    full_name: "udo admin",
    phone: "555-0104",
    user_roles: [ {role: UserRole::ORG_ADMIN, organization_id: organizations.fetch("udo").id} ],
  },
  {
    email: "udo.admin2@#{EMAIL_DOMAIN}",
    full_name: "udo admin 2",
    phone: "555-0106",
    user_roles: [ {role: UserRole::ORG_ADMIN, organization_id: organizations.fetch("udo").id} ],
  },
  {
    email: "udo.ride.requester@#{EMAIL_DOMAIN}",
    full_name: "udo ride requester",
    phone: "555-0110",
    user_roles: [ {role: UserRole::RIDE_REQUESTER, organization_id: organizations.fetch("udo").id} ],
  },
  {
    email: "vdo.admin@#{EMAIL_DOMAIN}",
    full_name: "vdo admin",
    phone: "555-0105",
    user_roles: [ {role: UserRole::ORG_ADMIN, organization_id: organizations.fetch("vdo").id} ],
  },
  {
    email: "vdo.ride.requester@#{EMAIL_DOMAIN}",
    full_name: "vdo ride requester",
    phone: "555-0111",
    user_roles: [ {role: UserRole::RIDE_REQUESTER, organization_id: organizations.fetch("vdo").id} ],
  },
  {
    email: "unvetted.driver.1@#{EMAIL_DOMAIN}",
    full_name: "unvetted driver 1",
    phone: "555-0106",
    user_roles: [ {role: UserRole::DRIVER, organization_id: nil} ],
    driver_qualifications: [],
  },
  {
    email: "vdo.vetted.driver.1@#{EMAIL_DOMAIN}",
    full_name: "vdo vetted driver 1",
    phone: "555-0107",
    user_roles: [ {role: UserRole::DRIVER, organization_id: nil} ],
    driver_qualifications: [ DriverQualification::QUALIFICATION_CWS_VETTED ],
  },
  {
    email: "unvetted.driver.2@#{EMAIL_DOMAIN}",
    full_name: "unvetted driver 2",
    phone: "555-0108",
    user_roles: [ {role: UserRole::DRIVER, organization_id: nil} ],
    driver_qualifications: [],
  },
  {
    email: "vdo.vetted.driver.2@#{EMAIL_DOMAIN}",
    full_name: "vdo vetted driver 2",
    phone: "555-0109",
    user_roles: [ {role: UserRole::DRIVER, organization_id: nil} ],
    driver_qualifications: [ DriverQualification::QUALIFICATION_CWS_VETTED ],
  },
  {
    email: "driver@#{EMAIL_DOMAIN}",
    full_name: "driver",
    phone: "555-0113",
    user_roles: [ {role: UserRole::DRIVER, organization_id: nil} ],
    driver_qualifications: [],
  },
]

begin
  seed_executor = upsert_seed_executor!(email: "seed.executor@#{EMAIL_DOMAIN}")

  user_definitions.each do |user_definition|
    result = UnitsOfWork::UpsertUser.execute(
      executor_id: seed_executor.id,
      params: {
        email: user_definition.fetch(:email),
        full_name: user_definition.fetch(:full_name),
        preferred_name: default_preferred_name(user_definition.fetch(:full_name)),
        phone: user_definition.fetch(:phone),
        user_roles: user_definition.fetch(:user_roles),
        driver_qualifications: user_definition.fetch(:driver_qualifications, []),
        password: DEFAULT_PASSWORD,
      }
    )
    next if result.success?

    raise "Failed to seed user #{user_definition.fetch(:email)}: #{result.errors.full_messages.join(', ')}"
  end
  udo_requester = User.find_by!(email: "udo.ride.requester@#{EMAIL_DOMAIN}")
  vdo_requester = User.find_by!(email: "vdo.ride.requester@#{EMAIL_DOMAIN}")

  [
    {
      organization: organizations.fetch("udo"),
      requester: udo_requester,
      date: 1.year.from_now.to_date,
      short_description: "Doctor appointment - UDO client",
      contact_full_name: "udo ride requester",
    },
    {
      organization: organizations.fetch("vdo"),
      requester: vdo_requester,
      date: (1.year + 1.week).from_now.to_date,
      short_description: "Physical therapy - VDO client",
      contact_full_name: "vdo ride requester",
    },
  ].each do |attrs|
    next if RideRequest.exists?(organization: attrs[:organization], short_description: attrs[:short_description])

    address = Address.find_or_create_by!(
      name: "#{attrs[:organization].abbreviation} Pickup Location",
      street_address: "123 Main St",
      city: "Harrisonburg",
      state: "VA",
      zip: "22801",
      country: "US"
    )

    RideRequest::Published.create!(
      organization: attrs[:organization],
      requester: attrs[:requester],
      date: attrs[:date],
      short_description: attrs[:short_description],
      contact_full_name: attrs[:contact_full_name],
      pick_up_address: address,
      ride_description_public: "Ride to appointment",
      desired_driver_gender: "none",
      draft: false
    )
  end
  driver = User.find_by!(email: "driver@#{EMAIL_DOMAIN}")
  other_driver = User.find_by!(email: "unvetted.driver.1@#{EMAIL_DOMAIN}")
  udo = organizations.fetch("udo")

  seed_address = Address.find_or_create_by!(
    name: "Seed Pickup Location",
    street_address: "456 Oak Ave",
    city: "Harrisonburg",
    state: "VA",
    zip: "22801",
    country: "US"
  )

  ride_request_seeds = [
    {
      short_description: "Completed ride - driver",
      completed: true,
      assign_driver: driver,
      has_enough_drivers: true,
    },
    {
      short_description: "My assigned ride (single driver)",
      assign_driver: driver,
      has_enough_drivers: true,
      requires_multiple_drivers: false,
    },
    {
      short_description: "My assigned ride (needs more drivers)",
      assign_driver: driver,
      has_enough_drivers: false,
      requires_multiple_drivers: true,
    },
    {
      short_description: "Available ride for drivers",
    },
    {
      short_description: "Other driver's ride (single, full)",
      assign_driver: other_driver,
      has_enough_drivers: true,
      requires_multiple_drivers: false,
    },
    {
      short_description: "Other driver's ride (multi, needs more)",
      assign_driver: other_driver,
      has_enough_drivers: false,
      requires_multiple_drivers: true,
    },
  ]

  ride_request_seeds.each do |attrs|
    existing = RideRequest.find_by(organization: udo, short_description: attrs[:short_description])
    if existing
      if attrs[:completed]
        existing.update_columns(date: 1.month.ago.to_date, completed: true)
      end
      next
    end

    rr = RideRequest::Published.create!(
      organization: udo,
      requester: udo_requester,
      date: 1.year.from_now.to_date,
      short_description: attrs[:short_description],
      contact_full_name: "udo ride requester",
      pick_up_address: seed_address,
      ride_description_public: "Seed ride request",
      desired_driver_gender: "none",
      draft: false,
      has_enough_drivers: attrs.fetch(:has_enough_drivers, false),
      requires_multiple_drivers: attrs.fetch(:requires_multiple_drivers, false),
    )

    if attrs[:completed]
      rr.update_columns(date: 1.month.ago.to_date, completed: true)
    end

    if attrs[:assign_driver]
      DriverAssignment.find_or_create_by!(ride_request: rr, driver: attrs[:assign_driver])
    end
  end

rescue StandardError => error
  warn "SEED FAILURE: #{error.message}"
  warn(error.backtrace.first(10).join("\n")) if error.backtrace.present?
  abort("db:seed failed")
end
