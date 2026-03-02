class User < ApplicationRecord
  include UserConcerns::HasEmail
  include UserConcerns::HasIdentities
  include UserConcerns::HasHuman
  include UserConcerns::HasDriverQualifications
  include UserConcerns::HasRoles
end
