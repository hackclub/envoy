require "rails_helper"

RSpec.describe AdminMailer, type: :mailer do
  describe "#new_application_notification" do
    let(:owner) { create(:admin, notify_new_applications: true) }
    let(:event) { create(:event, admin: owner) }
    let(:participant) { create(:participant) }
    let(:application) { create(:visa_letter_application, event: event, participant: participant) }

    it "emails the event owner when they have no explicit preference" do
      mail = described_class.new_application_notification(application)
      expect(mail.to).to include(owner.email)
    end

    it "does not email the event owner who opted out for this event" do
      create(:event_notification_preference, admin: owner, event: event, notify_new_applications: false)

      mail = described_class.new_application_notification(application)
      expect(mail.to).to be_blank
    end

    it "emails a super admin only for events they have not opted out of" do
      super_admin = create(:admin, :super_admin, notify_new_applications: true)
      create(:event_notification_preference, admin: super_admin, event: event, notify_new_applications: false)

      mail = described_class.new_application_notification(application)
      expect(Array(mail.to)).not_to include(super_admin.email)
    end

    it "emails additional event admins who want notifications for the event" do
      collaborator = create(:admin, notify_new_applications: true)
      create(:event_admin, admin: collaborator, event: event)

      mail = described_class.new_application_notification(application)
      expect(mail.to).to include(collaborator.email)
    end
  end
end
