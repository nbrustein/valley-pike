class Human < ApplicationRecord
  self.table_name = "humans"

  belongs_to :user
end
