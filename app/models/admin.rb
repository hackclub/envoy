class Admin < ApplicationRecord
  devise :rememberable, :trackable, :lockable,
         :omniauthable, omniauth_providers: [ :hack_club ]

  has_many :events, dependent: :restrict_with_error
  has_many :event_admins, dependent: :destroy
  has_many :collaborative_events, through: :event_admins, source: :event
  has_many :reviewed_applications, class_name: "VisaLetterApplication", foreign_key: :reviewed_by_id, dependent: :nullify
  has_many :activity_logs, dependent: :nullify

  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, uniqueness: true
  validates :uid, uniqueness: { scope: :provider }, allow_nil: true

  def self.from_omniauth(auth)
    admin = find_by(provider: auth.provider, uid: auth.uid)
    admin ||= find_by(email: auth.info.email)

    return nil unless admin

    admin.update!(
      provider: auth.provider,
      uid: auth.uid,
      first_name: auth.info.first_name || auth.info.name&.split&.first || admin.first_name,
      last_name: auth.info.last_name || auth.info.name&.split&.last || admin.last_name
    )
    admin
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def rememberable_value
    remember_token || generate_remember_token!
  end

  def generate_remember_token!
    update_column(:remember_token, Devise.friendly_token)
    remember_token
  end
end
