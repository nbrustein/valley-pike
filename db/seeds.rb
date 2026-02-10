# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

user = User.first_or_create!
user.update!(email: "email@example.com") unless user.email == "email@example.com"

identity = Identity.find_or_initialize_by(kind: "password", email: "email@example.com")
identity.user = user
identity.email = "email@example.com"
identity.password = "password"
identity.password_confirmation = "password"
identity.skip_password_validation = true
identity.skip_password_strength_validation = true
identity.save!
