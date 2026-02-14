class User < ApplicationRecord
  include UserConcerns::HasEmail
  include UserConcerns::HasIdentities
  include UserConcerns::HasHuman
  include UserConcerns::CanBeDisabled
  include UserConcerns::HasRoles
end
