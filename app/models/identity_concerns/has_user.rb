# frozen_string_literal: true

module IdentityConcerns
  module HasUser
    extend ActiveSupport::Concern

    included do
      belongs_to :user
    end
  end
end
