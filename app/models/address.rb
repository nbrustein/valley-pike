class Address < ApplicationRecord
  validates :name, :street_address, :city, :state, :country, presence: true
end
