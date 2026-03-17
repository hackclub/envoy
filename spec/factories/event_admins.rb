FactoryBot.define do
  factory :event_admin do
    association :event
    association :admin
  end
end
