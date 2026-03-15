class AdminOrganizationMutatePolicy < ApplicationPolicy
  include CrudsRecordsWithUnitsOfWork

  def new?
    user&.has_role_permissions?(UserRole::VANITA_ADMIN) || false
  end

  # users who are allowed to mutate organizations are allowed to
  # mutate any organization
  def can_mutate?(uow_or_target_record)
    true
  end

  def target_record_from_uow
    uow&.organization
  end
end
