class AdminOrganizationsIndexController < ApplicationController
  include Memery

  def index
    authorize(nil, :index?, policy_class: AdminOrganizationViewPolicy)
    @organizations = policy_scope(Organization, policy_scope_class: AdminOrganizationViewPolicy::Scope)
      .order(name: :asc)
  end
end
