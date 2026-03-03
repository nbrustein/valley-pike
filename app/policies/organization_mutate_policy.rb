class OrganizationMutatePolicy < ApplicationPolicy
  def uow
    record.is_a?(UnitOfWork) ? record : nil
  end

  def target_organization
    return record if record.is_a?(Organization)
    return uow.organization if uow&.respond_to?(:organization)

    nil
  end

  def new?
    user&.has_role_permissions?(UserRole::VANITA_ADMIN) || false
  end

  def create?
    return false unless new?
    return false unless uow

    true
  end

  def edit?
    return false unless new?
    return false unless target_organization

    true
  end

  def update?
    edit? && create?
  end
end
