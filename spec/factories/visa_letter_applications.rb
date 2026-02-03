FactoryBot.define do
  factory :visa_letter_application do
    association :participant
    association :event
    status { "pending_verification" }

    trait :pending_approval do
      status { "pending_approval" }
      submitted_at { 1.day.ago }
      participant { association :participant, :verified }
    end

    trait :approved do
      status { "approved" }
      submitted_at { 3.days.ago }
      reviewed_at { 1.day.ago }
      association :reviewed_by, factory: :admin
      participant { association :participant, :verified }
    end

    trait :rejected do
      status { "rejected" }
      submitted_at { 3.days.ago }
      reviewed_at { 1.day.ago }
      rejection_reason { "Incomplete documentation" }
      rejection_type { "soft" }
      association :reviewed_by, factory: :admin
      participant { association :participant, :verified }
    end

    trait :soft_rejected do
      rejected
      rejection_type { "soft" }
    end

    trait :hard_rejected do
      rejected
      rejection_type { "hard" }
    end

    trait :letter_sent do
      status { "letter_sent" }
      submitted_at { 5.days.ago }
      reviewed_at { 3.days.ago }
      letter_generated_at { 2.days.ago }
      letter_sent_at { 2.days.ago }
      association :reviewed_by, factory: :admin
      participant { association :participant, :verified }
    end
  end
end
