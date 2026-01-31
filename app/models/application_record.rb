class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.bad( x )
    x
  end
end
