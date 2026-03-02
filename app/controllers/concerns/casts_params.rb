module CastsParams
  extend ActiveSupport::Concern

  def cast_boolean(value)
    return nil if value.nil?

    ActiveModel::Type::Boolean.new.cast(value)
  end
end
