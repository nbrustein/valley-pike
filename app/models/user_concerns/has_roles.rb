# frozen_string_literal: true

module UserConcerns
  module HasRoles
    extend ActiveSupport::Concern
    include Memery

    included do
      has_many :user_roles, dependent: :destroy
    end

    memoize def has_role?(organization_id)
      user_roles.where(organization_id: [ organization_id, nil ]).exists?
    end

    memoize def has_role_permissions?(role)
      user_roles.any? {|user_role| user_role.has_role_permissions?(role) }
    end

    def roles_with_permissions(role)
      user_roles.select {|user_role| user_role.has_role_permissions?(role) }
    end
  end
end
