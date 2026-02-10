module IdentityConcerns
  module CanBeDisabled
    extend ActiveSupport::Concern

    def active_for_authentication?
      super && disabled_at.nil? && !user&.disabled?
    end

    def inactive_message
      :inactive
    end

    def active_for_magic_link_authentication?
      active_for_authentication?
    end

    def magic_link_inactive_message
      inactive_message
    end
  end
end
