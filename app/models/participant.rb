class Participant < ApplicationRecord
  has_many :visa_letter_applications, dependent: :destroy
  has_many :events, through: :visa_letter_applications

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :full_name, presence: true, length: { minimum: 2, maximum: 200 }
  validates :date_of_birth, presence: true
  validates :country_of_birth, presence: true
  validates :phone_number, presence: true
  validates :full_street_address, presence: true, length: { minimum: 10 }

  validate :minimum_age

  before_validation :normalize_email

  VERIFICATION_CODE_EXPIRY = 30.minutes
  VERIFICATION_CODE_RESEND_DELAY = 2.minutes
  MAX_VERIFICATION_ATTEMPTS = 5

  def email_verified?
    email_verified_at.present?
  end

  def generate_verification_code!
    self.verification_code = SecureRandom.random_number(1_000_000).to_s.rjust(6, "0")
    self.verification_code_sent_at = Time.current
    self.verification_attempts = 0
    self.email_verified_at = nil
    save!
  end

  def verify_code!(code)
    return false if verification_code.blank?
    return false if verification_code_expired?
    return false if verification_attempts >= MAX_VERIFICATION_ATTEMPTS

    if verification_code == code
      self.email_verified_at = Time.current
      self.verification_code = nil
      self.verification_code_sent_at = nil
      save!
      true
    else
      increment!(:verification_attempts)
      false
    end
  end

  def verification_code_expired?
    return true if verification_code_sent_at.nil?
    verification_code_sent_at < VERIFICATION_CODE_EXPIRY.ago
  end

  def can_resend_verification_code?
    verification_code_sent_at.nil? || verification_code_sent_at < VERIFICATION_CODE_RESEND_DELAY.ago
  end

  def verification_attempts_exceeded?
    verification_attempts >= MAX_VERIFICATION_ATTEMPTS
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def minimum_age
    return unless date_of_birth.present?

    if date_of_birth > 13.years.ago.to_date
      errors.add(:date_of_birth, "must be at least 13 years old")
    end
  end
end
