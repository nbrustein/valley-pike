# frozen_string_literal: true

module UserConcerns
  module CanBeDisabled
    extend ActiveSupport::Concern

    def disabled?
      disabled_at.present?
    end
  end
end
