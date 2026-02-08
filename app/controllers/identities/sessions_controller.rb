class Identities::SessionsController < Devise::Passwordless::SessionsController
  def create
    email = params.dig(resource_name, :email).to_s

    if email.blank?
      self.resource = resource_class.new
      resource.errors.add(:email, "can't be blank")
      respond_with_navigational(resource) { render :new, status: :unprocessable_entity }
      return
    end

    self.resource = resource_class.find_or_create_magic_link_identity!(email)

    unless resource.active_for_magic_link_authentication?
      set_flash_message!(:alert, resource.magic_link_inactive_message)
      respond_with_navigational(resource) { render :new, status: :forbidden }
      return
    end

    resource.send_magic_link
    set_flash_message!(:notice, :magic_link_sent)
    respond_with resource, location: after_magic_link_sent_path_for(resource_name)
  end
end
