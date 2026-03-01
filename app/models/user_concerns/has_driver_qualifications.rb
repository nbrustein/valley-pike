# frozen_string_literal: true

module UserConcerns
  module HasDriverQualifications
    extend ActiveSupport::Concern

    included do
      has_many :driver_qualifications, dependent: :destroy
    end
  end
end
