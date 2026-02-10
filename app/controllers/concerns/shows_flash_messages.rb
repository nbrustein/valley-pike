module ShowsFlashMessages
  extend ActiveSupport::Concern

  private

  def set_flash_message(key, kind, options={})
    message = find_message(kind, options)
    if options[:now]
      flash.now[key] = message if message.present?
    else
      flash[key] = message if message.present?
    end
  end

  def set_flash_message!(key, kind, options={})
    set_flash_message(key, kind, options) if is_flashing_format?
  end

  def translation_scope
    "devise.sessions"
  end

  def devise_i18n_options(options)
    options
  end

  def find_message(kind, options={})
    options[:scope] ||= translation_scope
    options[:default] = Array(options[:default]).unshift(kind.to_sym)
    options[:resource_name] = resource_name
    options = devise_i18n_options(options)
    I18n.t("#{options[:resource_name]}.#{kind}", **options)
  end
end
