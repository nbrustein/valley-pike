module RideRequestsHelper
  include Memery

  memoize def show_ride_requests_index_link?
    RideRequestViewPolicy::Scope.new(current_user, nil).resolve.exists?
  end

  memoize def ride_request_create_allowed?
    RideRequestMutatePolicy.new(current_user, nil).new?
  end

  def ride_request_edit_allowed?(ride_request)
    RideRequestMutatePolicy.new(current_user, ride_request).edit?
  end

  memoize def show_ride_request_org_column?
    policy = RideRequestViewPolicy.new(current_user, nil)
    organization_id_count = if policy.all_organizations_permitted?
      Organization.count
    else
      policy.permitted_organization_ids.compact.size
    end

    organization_id_count > 1
  end
end
