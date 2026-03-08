# This module implements the rules that
# * some users are allowed to create SOME users, and so can `new?`
# * users who can new? might be limited in what records the can create, so `create?``
#   respects the rules in `can_mutate?(unit_of_work)`
# * a user can edit any record that they would have been allowed to create, so `edit?`
#   respects the rules in `can_mutate?(target_record)`
# * when submitting the edit form, a user can submit if they are allowed to edit the
#   target record and the they would have been allowed to create a record with the
#   params that they are currently submitting, so `update?` is `edit? && create?`
#
# To use this module, a Policy must implement the following methods:
# new?
# can_mutate?(uow_or_target_record)
# target_record_from_uow

module CrudsRecordsWithUnitsOfWork
  extend ActiveSupport::Concern
  include Memery

  # Methods that are run on form submission (i.e. create? and update?) are instantiated with
  # the record being the UnitOfWork that will be executed to process the form submission.
  # Methods that are run on form display (i.e. edit? and new?) are instantiated with the nullable
  # target user that will be used to fill in the form's defaults.
  def uow
    record.is_a?(UnitOfWork) ? record : nil
  end

  def target_record
    record.is_a?(ApplicationRecord) ? record : uow ? target_record_from_uow : nil
  end

  def create?
    return false unless new?
    return false unless uow
    can_mutate?(uow)
  end

  # If the executor would have been allowed to create the target record,
  # then they are allowed to edit it.
  def edit?
    return false unless new?
    return false unless target_record
    can_mutate?(target_record)
  end

  # If the executor is allowed to edit the target record, and they would be allowed
  # to create a record with the current params, then they are allowed to update the record.
  def update?
    edit? && create?
  end
end
