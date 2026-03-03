class OrganizationMutatePolicy < ApplicationPolicy
  def uow
    record.is_a?(UnitOfWork) ? record : nil
  end

  def new?
    user&.has_role_permissions?(UserRole::VANITA_ADMIN) || false
  end

  def create?
    return false unless new?
    return false unless uow

    true
  end
end
