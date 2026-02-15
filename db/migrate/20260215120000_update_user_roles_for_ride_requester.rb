class UpdateUserRolesForRideRequester < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :user_roles, name: "user_roles_role_check"
    add_check_constraint :user_roles,
                         "role IN ('developer', 'vanita_admin', 'org_admin', 'ride_requester', 'driver')",
                         name: "user_roles_role_check"

    add_check_constraint :user_roles,
                         "(role IN ('developer', 'vanita_admin') AND organization_id IS NULL) OR " \
                         "(role IN ('org_admin', 'ride_requester') AND organization_id IS NOT NULL) OR " \
                         "(role = 'driver')",
                         name: "user_roles_organization_id_check"
  end
end
