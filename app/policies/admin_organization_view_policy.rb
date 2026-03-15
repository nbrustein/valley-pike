class AdminOrganizationViewPolicy < ApplicationPolicy
  memoize def index?
    user&.has_role_permissions?(UserRole::VANITA_VIEWER) || false
  end

  memoize def show?
    index?
  end

  class Scope < Scope
    def resolve
      return Organization.where("FALSE") unless policy.index?

      Organization.all
    end

    private

    memoize def policy
      AdminOrganizationViewPolicy.new(user, nil)
    end
  end
end
