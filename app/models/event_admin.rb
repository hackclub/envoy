class EventAdmin < ApplicationRecord
  belongs_to :event
  belongs_to :admin

  validates :admin_id, uniqueness: { scope: :event_id, message: "is already an admin for this event" }
end
