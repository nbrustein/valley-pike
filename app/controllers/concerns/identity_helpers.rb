# frozen_string_literal: true

module IdentityHelpers
  extend ActiveSupport::Concern

  included do
    helper_method :resource, :resource_name
    before_action :ensure_devise_mapping
  end

  private

  def resource_name
    :identity
  end

  def resource_class
    Identity
  end

  def resource
    @resource
  end

  def resource=(resource)
    @resource = resource
  end

  def email_param
    params.dig(resource_name, :email).to_s
  end

  def render_sessions_new_with_errors(errors)
    self.resource = resource_class.new
    errors.each {|attribute, message| resource.errors.add(attribute, message) }
    render "devise/sessions/new", status: :unprocessable_content
  end

  def ensure_devise_mapping
    request.env["devise.mapping"] ||= Devise.mappings[resource_name]
  end
end
