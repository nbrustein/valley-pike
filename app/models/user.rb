class User < ApplicationRecord
  include UserConcerns::HasIdentities
  include UserConcerns::CanBeDisabled
end
