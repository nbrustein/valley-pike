class UserMutatePolicy < ApplicationPolicy
  include IsUserPolicy

  # Methods that are run on form submission (i.e. create? and update?) are instantiated with
  # the record being the UnitOfWork that will be executed to process the form submission.
  # Methods that are run on form display (i.e. edit? and new?) are instantiated with the nullable
  # target user that will be used to fill in the form's defaults.
  def uow
    record.is_a?(UnitOfWork) ? record : nil
  end

  def target_user
    record.is_a?(User) ? record : uow&.respond_to?(:user) ? uow.user : nil
  end

  def new?
    user&.has_role_permissions?(UserRole::ORG_ADMIN) || false
  end

  def create?
    return false unless new?
    return false unless uow
    can_create?(user_roles: uow.user_roles)
  end

  # If the current user would have been allowed to create the target user,
  # then they are allowed to edit them.
  def edit?
    return false unless new?
    return false unless target_user
    can_create?(user_roles: target_user.user_roles)
  end

  # If the current user is allowed to edit the target user, and they would be allowed
  # to create a user with the current params, then they are allowed to update the user.
  def update?
    edit? && create?
  end

  def manage_drivers?
    user&.has_role_permissions?(UserRole::VANITA_ADMIN) || false
  end

  class OrganizationScope < Scope
    include IsUserPolicy

    def resolve
      Organization.where(id: organization_ids_with_org_admin_permissions)
    end

    private

    memoize def policy
      UserMutatePolicy.new(user, nil)
    end
  end

  def manageable_roles
    return UserRole::ROLES.to_a if user&.has_role_permissions?(UserRole::DEVELOPER)
    return [ UserRole::ORG_ADMIN, UserRole::RIDE_REQUESTER, UserRole::DRIVER ] if user&.has_role_permissions?(UserRole::VANITA_ADMIN)
    return [ UserRole::RIDE_REQUESTER ] if user&.has_role_permissions?(UserRole::ORG_ADMIN)
    []
  end

  private

  def can_create?(user_roles:)
    roles_allowed?(user_roles)
  end

  def roles_allowed?(user_roles)
    roles, organization_ids = roles_and_organization_ids(user_roles)
    return false if roles.empty?
    return false if (roles.uniq - manageable_roles).any?
    return false if (organization_ids.compact.uniq - organization_ids_with_org_admin_permissions).any?

    true
  end

  def roles_and_organization_ids(user_roles)
    roles = []
    organization_ids = []

    user_roles.each do |user_role|
      if user_role.respond_to?(:role)
        roles << user_role.role
        organization_ids << user_role.organization_id
      else
        roles << (user_role[:role] || user_role["role"])
        organization_ids << (user_role[:organization_id] || user_role["organization_id"])
      end
    end

    [ roles, organization_ids ]
  end
end
