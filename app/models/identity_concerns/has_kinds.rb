module IdentityConcerns
  module HasKinds
    extend ActiveSupport::Concern

    KINDS = %w[magic_link password oauth].freeze

    included do
      validates :kind, presence: true, inclusion: {in: KINDS}
    end
  end
end
