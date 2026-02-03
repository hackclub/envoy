class VisaLetterApplication < ApplicationRecord
  belongs_to :participant
  belongs_to :event
  belongs_to :reviewed_by, class_name: "Admin", optional: true

  has_one_attached :letter_pdf

  STATUSES = %w[
    pending_verification
    pending_approval
    approved
    rejected
    letter_sent
  ].freeze

  REJECTION_TYPES = %w[soft hard].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :reference_number, presence: true, uniqueness: true
  validates :rejection_reason, presence: true, if: -> { status == "rejected" }
  validates :rejection_type, presence: true, inclusion: { in: REJECTION_TYPES }, if: -> { status == "rejected" }
  validates :participant_id, uniqueness: { scope: :event_id, message: "already has an application for this event" }

  before_validation :generate_reference_number, on: :create
  before_validation :generate_verification_code, on: :create

  scope :pending_verification, -> { where(status: "pending_verification") }
  scope :pending_approval, -> { where(status: "pending_approval") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :letter_sent, -> { where(status: "letter_sent") }
  scope :hard_rejected, -> { rejected.where(rejection_type: "hard") }
  scope :soft_rejected, -> { rejected.where(rejection_type: "soft") }

  def self.email_hard_rejected_for_event?(email, event)
    joins(:participant)
      .where(participants: { email: email.to_s.strip.downcase })
      .where(event: event)
      .hard_rejected
      .exists?
  end

  def pending_verification?
    status == "pending_verification"
  end

  def pending_approval?
    status == "pending_approval"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  def hard_rejected?
    rejected? && rejection_type == "hard"
  end

  def soft_rejected?
    rejected? && rejection_type == "soft"
  end

  def letter_sent?
    status == "letter_sent"
  end

  def mark_as_submitted!
    update!(
      status: "pending_approval",
      submitted_at: Time.current
    )
  end

  def approve!(admin, notes: nil)
    return false unless pending_approval?

    update!(
      status: "approved",
      reviewed_by: admin,
      reviewed_at: Time.current,
      admin_notes: notes
    )
    true
  end

  def reject!(admin, reason:, rejection_type:, notes: nil)
    return false unless pending_approval?

    update!(
      status: "rejected",
      reviewed_by: admin,
      reviewed_at: Time.current,
      rejection_reason: reason,
      rejection_type: rejection_type,
      admin_notes: notes
    )
    true
  end

  def downgrade_to_soft_reject!(admin)
    return false unless hard_rejected?

    update!(rejection_type: "soft")
    true
  end

  def can_reapply?
    soft_rejected?
  end

  def mark_letter_generated!
    update!(letter_generated_at: Time.current)
  end

  def mark_letter_sent!
    update!(
      status: "letter_sent",
      letter_sent_at: Time.current
    )
  end

  def can_be_approved?
    pending_approval?
  end

  def can_be_rejected?
    pending_approval?
  end

  private

  def generate_reference_number
    return if reference_number.present?

    loop do
      self.reference_number = "HC-#{SecureRandom.alphanumeric(8).upcase}"
      break unless VisaLetterApplication.exists?(reference_number: reference_number)
    end
  end

  def generate_verification_code
    return if verification_code.present?

    loop do
      self.verification_code = SecureRandom.hex(16).upcase
      break unless VisaLetterApplication.exists?(verification_code: verification_code)
    end
  end
end
