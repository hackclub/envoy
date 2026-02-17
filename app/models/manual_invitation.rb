class ManualInvitation < ApplicationRecord
  belongs_to :event
  belongs_to :admin
  belongs_to :visa_letter_application, optional: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create
  before_validation :normalize_email

  scope :pending, -> { where(claimed_at: nil) }
  scope :claimed, -> { where.not(claimed_at: nil) }

  def claimed?
    claimed_at.present?
  end

  def claim!(application)
    update!(
      claimed_at: Time.current,
      visa_letter_application: application
    )
  end

  private

  def generate_token
    return if token.present?

    loop do
      self.token = SecureRandom.urlsafe_base64(32)
      break unless ManualInvitation.exists?(token: token)
    end
  end

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
