class OrganizationsIndexController < ApplicationController
  include Memery

  def index
    authorize(nil, :index?, policy_class: OrganizationViewPolicy)
    @organizations = policy_scope(Organization, policy_scope_class: OrganizationViewPolicy::Scope)
      .order(name: :asc)
  end
end
