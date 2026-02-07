# frozen_string_literal: true

module UserConcerns
  module HasIdentities
    extend ActiveSupport::Concern

    included do
      has_many :identities, dependent: :destroy
    end
  end
end
