class User < ApplicationRecord
  include UserConcerns::HasIdentities
  include UserConcerns::CanBeDisabled

  def self.find_by_email(email)
    find_by(email: Identity.normalize_email(email))
  end
end
