class Admin < ApplicationRecord
  devise :rememberable, :trackable, :lockable,
         :omniauthable, omniauth_providers: [ :hack_club ]

  has_many :events, dependent: :restrict_with_error
  has_many :event_admins, dependent: :destroy
  has_many :collaborative_events, through: :event_admins, source: :event
  has_many :reviewed_applications, class_name: "VisaLetterApplication", foreign_key: :reviewed_by_id, dependent: :nullify
  has_many :activity_logs, dependent: :nullify
  has_many :event_notification_preferences, dependent: :destroy

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

  # Events whose applications this admin could receive notifications about.
  # Super admins can be notified about every event; other admins only about
  # events they own or collaborate on.
  def notifiable_events
    if super_admin?
      Event.all
    else
      Event.where(id: events.select(:id)).or(Event.where(id: collaborative_events.select(:id)))
    end
  end

  # Whether this admin wants new-application emails for the given event.
  # An explicit per-event preference always takes precedence. Without one, an
  # admin only falls back to their account-wide default for events they're
  # explicitly on (owner or collaborator). Super admins are not notified about
  # events they haven't been added to unless they opt in per-event.
  def notify_new_applications_for?(event)
    preference = event_notification_preferences.find_by(event_id: event.id)
    return preference.notify_new_applications unless preference.nil?

    return false unless event.admin?(self)

    notify_new_applications?
  end

  def rememberable_value
    remember_token || generate_remember_token!
  end

  def generate_remember_token!
    update_column(:remember_token, Devise.friendly_token)
    remember_token
  end
end
