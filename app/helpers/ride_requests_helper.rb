module RideRequestsHelper
  include Memery

  memoize def show_ride_requests_index_link?
    RideRequestViewPolicy::Scope.new(current_user, nil).resolve.exists?
  end

  memoize def show_ride_request_org_column?
    policy = RideRequestViewPolicy.new(current_user, nil)
    policy.permitted_organization_ids.compact.size > 1
  end
end
