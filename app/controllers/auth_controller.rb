# frozen_string_literal: true

class AuthController < ApplicationController
  include IdentityHelpers

  before_action :allow_params_authentication!, only: :create_password_session

  # magic link sessions are created by devise, so we don't need an explicit action for that here

  def create_password_session
    email = email_param
    password = password_param
    errors = {}
    errors[:email] = "can't be blank" if email.blank?
    errors[:password] = "can't be blank" if password.blank?
    return render_sessions_new_with_errors(errors) if errors.any?

    self.resource = warden.authenticate!(scope: resource_name)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    redirect_to after_sign_in_path_for(resource)
  end

  private

  def password_param
    params.dig(resource_name, :password).to_s
  end
end
