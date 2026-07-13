FactoryBot.define do
  factory :api_key do
    sequence(:name) { |n| "API Key #{n}" }
    association :admin
    created_by { admin }

    trait :revoked do
      revoked_at { Time.current }
    end
  end
end
