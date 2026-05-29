class EventNotificationPreference < ApplicationRecord
  belongs_to :admin
  belongs_to :event

  validates :admin_id, uniqueness: { scope: :event_id }
end
