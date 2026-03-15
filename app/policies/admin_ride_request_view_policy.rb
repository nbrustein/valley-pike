class AdminRideRequestViewPolicy < ApplicationPolicy
  include IsOrganizationAwarePolicy

  memoize def index?
      roles_granting_permissions.any? ||
      false
  end

  def show?
    index? && Scope.new(user, RideRequest).resolve.exists?(record.id)
  end

  memoize def roles_granting_permissions
    return [] if user.nil?

    user&.roles_with_permissions(UserRole::RIDE_REQUESTER) + user&.roles_with_permissions(UserRole::VANITA_VIEWER)
  end

  class Scope < Scope
    def resolve
      return RideRequest.where("FALSE") unless policy.index?

      published_requests.or(draft_requests)
    end

    private

    def published_requests
      published_requests = RideRequest.published
      return published_requests if user.has_role_permissions?(UserRole::VANITA_VIEWER)

      published_requests.where(organization_id: policy.permitted_organization_ids)
    end

    def draft_requests
      draft_requests = RideRequest.where(draft: true)
      return draft_requests if user.has_role_permissions?(UserRole::DEVELOPER)

      draft_requests.where(requester_id: user.id)
    end

    memoize def policy
      AdminRideRequestViewPolicy.new(user, nil)
    end
  end
end
