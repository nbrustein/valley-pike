class Human < ApplicationRecord
  self.table_name = "humans"

  belongs_to :user

  validates :full_name, :preferred_name, presence: true
end
