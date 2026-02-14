# frozen_string_literal: true

module UserConcerns
  module HasHuman
    extend ActiveSupport::Concern

    included do
      has_one :human, dependent: :destroy, inverse_of: :user
      validates :human, presence: true
    end
  end
end
