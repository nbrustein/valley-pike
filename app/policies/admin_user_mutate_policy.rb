class AdminUserMutatePolicy < ApplicationPolicy
  include CrudsRecordsWithUnitsOfWork

  def new?
    user&.has_role_permissions?(UserRole::VANITA_ADMIN) ||
      false
  end

  def manageable_roles
    return UserRole::ROLES.to_a if user&.has_role_permissions?(UserRole::DEVELOPER)
    return [
      UserRole::ORG_ADMIN,
      UserRole::RIDE_REQUESTER,
      UserRole::DRIVER,
      UserRole::VANITA_VIEWER,
    ] if user&.has_role_permissions?(UserRole::VANITA_ADMIN)
    []
  end

  private

  def can_mutate?(uow_or_target_record)
    user_roles = uow_or_target_record.user_roles
    roles = user_roles.map {|user_role| user_role[:role] || user_role["role"] }
    return false if roles.empty?
    return false if (roles.uniq - manageable_roles).any?

    true
  end

  def target_record_from_uow
    uow&.user
  end
end
