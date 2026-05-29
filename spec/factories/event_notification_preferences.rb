FactoryBot.define do
  factory :event_notification_preference do
    association :admin
    association :event
    notify_new_applications { true }
  end
end
