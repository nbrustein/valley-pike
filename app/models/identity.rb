class Identity < ApplicationRecord
  include IdentityConcerns::HasKinds
  include IdentityConcerns::HasUser
  include IdentityConcerns::HasEmail
  include IdentityConcerns::SupportsPasswordAuthentication
  include IdentityConcerns::SupportsMagicLinks
  include IdentityConcerns::CanBeDisabled
  include IdentityConcerns::IsDeviseResource
end
