class RideRequest < ApplicationRecord
  DESIRED_DRIVER_GENDERS = %w[female female_accompaniment none].freeze

  belongs_to :organization
  belongs_to :requester, class_name: "User"
  belongs_to :pick_up_address, class_name: "Address", optional: true
  belongs_to :destination_address, class_name: "Address", optional: true
  has_many :driver_assignments
  has_many :drivers, through: :driver_assignments, source: :driver

  STATUS_DISPLAY = {
    draft: {label: "Draft", icon: "fa-file-pen"},
    request_sent: {label: "Request Sent", icon: "fa-paper-plane"},
    driver_assigned: {label: "Driver Assigned", icon: "fa-car"},
    complete: {label: "Complete", icon: "fa-circle-check"},
    canceled: {label: "Canceled", icon: "fa-ban"},
  }.freeze

  scope :published, -> { where(draft: false) }

  validates :desired_driver_gender, inclusion: {in: DESIRED_DRIVER_GENDERS}

  CANCELLABLE_STATUSES = %i[request_sent driver_assigned].freeze

  def status_key
    return :draft if draft?
    return :canceled if cancelled?
    return :complete if completed?
    return :driver_assigned if driver_assignments.any?

    :request_sent
  end

  def status_display
    STATUS_DISPLAY.fetch(status_key)
  end

  def cancellable?
    CANCELLABLE_STATUSES.include?(status_key)
  end

  validate :date_not_changed_to_past, if: -> { date.present? && (new_record? || date_changed?) }
  validate :cancellation_allowed, if: -> { cancelled_changed? && cancelled? }
  before_destroy :ensure_draft!

  private

  def date_not_changed_to_past
    errors.add(:date, "must not be in the past") if date < Date.today
  end

  def cancellation_allowed
    return if !draft_was && !cancelled_was && !completed_was

    errors.add(:base, "Only active requests can be canceled")
  end

  def ensure_draft!
    return if draft?

    errors.add(:base, "Only draft ride requests can be deleted")
    throw(:abort)
  end
end
