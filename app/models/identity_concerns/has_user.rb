module IdentityConcerns
  module HasUser
    extend ActiveSupport::Concern

    included do
      belongs_to :user, optional: true
    end
  end
end
