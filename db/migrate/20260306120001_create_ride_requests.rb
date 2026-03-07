class CreateRideRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :ride_requests, id: :uuid do |t|
      t.string :type, null: false
      t.boolean :draft, null: false
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :requester, null: false, foreign_key: {to_table: :users}, type: :uuid
      t.string :contact_full_name
      t.string :contact_phone
      t.string :contact_email
      t.date :date
      t.string :short_description
      t.string :appointment_time
      t.references :pick_up_address, foreign_key: {to_table: :addresses}, type: :uuid
      t.references :destination_address, foreign_key: {to_table: :addresses}, type: :uuid
      t.text :ride_description_public
      t.text :ride_description_private
      t.string :desired_driver_gender, null: false, default: "none"
      t.boolean :has_enough_drivers, null: false, default: false
      t.boolean :requires_multiple_drivers, null: false, default: false
      t.boolean :cancelled, null: false, default: false
      t.boolean :completed, null: false, default: false
      t.text :driver_notes
      t.text :requester_notes
      t.text :other_notes

      t.timestamps
    end

    add_check_constraint :ride_requests,
                         "type IN ('RideRequest::Draft', 'RideRequest::Published')",
                         name: "ride_requests_type_check"
    add_check_constraint :ride_requests,
                         "desired_driver_gender IN ('female', 'female_accompaniment', 'none')",
                         name: "ride_requests_desired_driver_gender_check"
    add_check_constraint :ride_requests,
                         "draft = true OR contact_full_name IS NOT NULL",
                         name: "ride_requests_contact_full_name_check"
    add_check_constraint :ride_requests,
                         "draft = true OR date IS NOT NULL",
                         name: "ride_requests_date_check"
    add_check_constraint :ride_requests,
                         "draft = true OR short_description IS NOT NULL",
                         name: "ride_requests_short_description_check"
    add_check_constraint :ride_requests,
                         "draft = true OR pick_up_address_id IS NOT NULL",
                         name: "ride_requests_pick_up_address_check"
    add_check_constraint :ride_requests,
                         "draft = true OR ride_description_public IS NOT NULL",
                         name: "ride_requests_ride_description_public_check"
  end
end
