class CreateMagicLinkIdentityController < ApplicationController
  include IdentityHelpers

  # POST /identity/magic_link_identity
  # This is what an unauthenticated user hits to create a magic link identity.
  def create_magic_link_identity
    email = email_param
    return if maybe_render_blank_email_error?(email)

    user = User.find_by_email(email)
    return if maybe_render_missing_user_error?(email, user)

    self.resource = resource_class.find_or_create_magic_link_identity_for_user!(user)
    return if maybe_render_inactive_link_error?(resource)

    send_magic_link_and_redirect(resource)
  end

  private def send_magic_link_and_redirect(resource)
    resource.send_magic_link
    set_flash_message!(:notice, :magic_link_sent)
    redirect_to after_magic_link_sent_path_for(resource_name)
  end

  private def maybe_render_inactive_link_error?(resource)
    unless resource.active_for_magic_link_authentication?
      set_flash_message!(:alert, resource.magic_link_inactive_message)
      render "devise/sessions/new", status: :forbidden
      return true
    end

    false
  end

  def maybe_render_blank_email_error?(email)
    if email.blank?
      render_sessions_new_with_errors(email: "can't be blank")
      return true
    end

    false
  end

  def maybe_render_missing_user_error?(_email, user)
    return false if user

    render_sessions_new_with_errors(email: "not found")
    true
  end

  def translation_scope
    "devise.passwordless"
  end
end
