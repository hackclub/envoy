class ApiKey < ApplicationRecord
  TOKEN_PREFIX = "envoy_".freeze

  belongs_to :admin
  belongs_to :created_by, class_name: "Admin"

  validates :name, presence: true, length: { maximum: 100 }
  validates :token_digest, presence: true, uniqueness: true

  scope :active, -> { where(revoked_at: nil) }

  # Plaintext token, only available immediately after generation.
  attr_reader :token

  before_validation :generate_token, on: :create

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  # Finds the active key matching a plaintext token, or nil.
  def self.authenticate(token)
    return nil if token.blank?

    active.find_by(token_digest: digest(token))
  end

  def revoked?
    revoked_at.present?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end

  private

  def generate_token
    return if token_digest.present?

    @token = "#{TOKEN_PREFIX}#{SecureRandom.hex(24)}"
    self.token_digest = self.class.digest(@token)
  end
end
