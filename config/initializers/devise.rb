require "devise/orm/active_record"

Devise.setup do |config|
  config.mailer_sender = "no-reply@example.com"

  # Use Devise::Passwordless mailer to send magic links.
  config.mailer = "Devise::Passwordless::Mailer"
  config.passwordless_tokenizer = "SignedGlobalIDTokenizer"

  # Keep normalization logic in the Identity model.
  config.authentication_keys = [ :email ]
  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]
end

Warden::Manager.after_set_user except: :fetch do |record, warden, _options|
  next unless record.is_a?(Identity)

  if record.kind == "magic_link" && record.user_id.nil?
    raise "Expected to have a user"
  end

  updates = {last_used_at: Time.current, last_used_ip: warden.request&.remote_ip}
  updates[:confirmed_at] = Time.current if record.confirmed_at.nil?

  record.update_columns(updates)
end
