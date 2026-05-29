require "rails_helper"

RSpec.describe Admin, type: :model do
  describe "validations" do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_length_of(:first_name).is_at_most(100) }
    it { should validate_length_of(:last_name).is_at_most(100) }
  end

  describe "associations" do
    it { should have_many(:events).dependent(:restrict_with_error) }
    it { should have_many(:reviewed_applications).class_name("VisaLetterApplication") }
    it { should have_many(:activity_logs).dependent(:nullify) }
    it { should have_many(:event_notification_preferences).dependent(:destroy) }
  end

  describe "#full_name" do
    it "returns the combined first and last name" do
      admin = build(:admin, first_name: "John", last_name: "Doe")
      expect(admin.full_name).to eq("John Doe")
    end
  end

  describe "#notifiable_events" do
    it "includes owned and collaborative events for a regular admin" do
      admin = create(:admin)
      owned = create(:event, admin: admin)
      collaborator_event = create(:event)
      create(:event_admin, admin: admin, event: collaborator_event)
      unrelated = create(:event)

      expect(admin.notifiable_events).to contain_exactly(owned, collaborator_event)
      expect(admin.notifiable_events).not_to include(unrelated)
    end

    it "includes every event for a super admin" do
      admin = create(:admin, :super_admin)
      event_one = create(:event)
      event_two = create(:event)

      expect(admin.notifiable_events).to contain_exactly(event_one, event_two)
    end
  end

  describe "#notify_new_applications_for?" do
    let(:admin) { create(:admin) }
    let(:event) { create(:event, admin: admin) }

    it "falls back to the account-wide default when no preference exists" do
      admin.update!(notify_new_applications: true)
      expect(admin.notify_new_applications_for?(event)).to be(true)

      admin.update!(notify_new_applications: false)
      expect(admin.notify_new_applications_for?(event)).to be(false)
    end

    it "uses the explicit per-event preference when present" do
      admin.update!(notify_new_applications: true)
      create(:event_notification_preference, admin: admin, event: event, notify_new_applications: false)

      expect(admin.notify_new_applications_for?(event)).to be(false)
    end
  end
end
