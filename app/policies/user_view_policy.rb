class UserViewPolicy < ApplicationPolicy
  memoize def index?
    user&.has_role_permissions?(UserRole::VANITA_VIEWER) ||
      false
  end

  class Scope < Scope
    def resolve
      return User.where("FALSE") unless policy.index?

      User.all
    end

    private

    memoize def policy
      UserViewPolicy.new(user, nil)
    end
  end
end
