class Address < ApplicationRecord
  validates :name, :street_address, :city, :state, :zip, :country, presence: true
end
