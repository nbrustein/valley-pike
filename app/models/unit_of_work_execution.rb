class UnitOfWorkExecution < ApplicationRecord
  belongs_to :executor, class_name: "User"

  # We save units of work before the execution starts, to have a log in the case of an interrupt,
  # so we have to accept nil here
  validates :result, inclusion: {in: %w[failure success]}, allow_nil: true
end
