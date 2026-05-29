require "rails_helper"

RSpec.describe EventNotificationPreference, type: :model do
  describe "associations" do
    it { should belong_to(:admin) }
    it { should belong_to(:event) }
  end

  describe "validations" do
    subject { build(:event_notification_preference) }

    it { should validate_uniqueness_of(:admin_id).scoped_to(:event_id).case_insensitive }
  end
end
