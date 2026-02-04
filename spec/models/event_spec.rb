require "rails_helper"

RSpec.describe Event, type: :model do
  describe "validations" do
    subject { build(:event) }

    it { should validate_presence_of(:name) }
    # slug is auto-generated, so presence is ensured by the callback
    it { should validate_uniqueness_of(:slug) }
    it { should validate_presence_of(:venue_name) }
    it { should validate_presence_of(:venue_address) }
    it { should validate_presence_of(:city) }
    it { should validate_presence_of(:country) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_presence_of(:contact_email) }

    it "validates slug format" do
      event = build(:event, slug: "Invalid Slug!")
      expect(event).not_to be_valid
      expect(event.errors[:slug]).to be_present
    end

    it "validates end_date is after start_date" do
      event = build(:event, start_date: Date.tomorrow, end_date: Date.today)
      expect(event).not_to be_valid
      expect(event.errors[:end_date]).to include("must be after start date")
    end

    it "validates application_deadline is before start_date" do
      event = build(:event, start_date: 1.month.from_now, application_deadline: 2.months.from_now)
      expect(event).not_to be_valid
      expect(event.errors[:application_deadline]).to include("must be before start date")
    end
  end

  describe "associations" do
    it { should belong_to(:admin) }
    it { should have_one(:letter_template).dependent(:destroy) }
    it { should have_many(:visa_letter_applications).dependent(:restrict_with_error) }
    it { should have_many(:participants).through(:visa_letter_applications) }
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active events" do
        active_event = create(:event, active: true)
        inactive_event = create(:event, active: false)

        expect(Event.active).to include(active_event)
        expect(Event.active).not_to include(inactive_event)
      end
    end

    describe ".upcoming" do
      it "returns events with start_date in the future" do
        upcoming = create(:event, start_date: 1.month.from_now, end_date: 1.month.from_now + 2.days)
        past = create(:event, :past)

        expect(Event.upcoming).to include(upcoming)
        expect(Event.upcoming).not_to include(past)
      end
    end
  end

  describe "#accepting_applications?" do
    it "returns true when active, applications_open, and no deadline passed" do
      event = build(:event, active: true, applications_open: true, application_deadline: nil)
      expect(event.accepting_applications?).to be true
    end

    it "returns false when not active" do
      event = build(:event, active: false, applications_open: true)
      expect(event.accepting_applications?).to be false
    end

    it "returns false when applications_open is false" do
      event = build(:event, active: true, applications_open: false)
      expect(event.accepting_applications?).to be false
    end

    it "returns false when deadline has passed" do
      event = build(:event, active: true, applications_open: true, application_deadline: 1.day.ago)
      expect(event.accepting_applications?).to be false
    end
  end

  describe "#date_range" do
    it "formats dates in the same month" do
      event = build(:event, start_date: Date.new(2026, 6, 15), end_date: Date.new(2026, 6, 17))
      expect(event.date_range).to eq("June 15 - 17, 2026")
    end
  end

  describe "#full_address" do
    it "combines venue details" do
      event = build(:event, venue_name: "Convention Center", venue_address: "123 Main St", city: "San Francisco", country: "United States")
      expect(event.full_address).to eq("Convention Center, 123 Main St, San Francisco, United States")
    end
  end

  describe "slug generation" do
    it "auto-generates slug from name on create" do
      event = create(:event, name: "My Cool Event", slug: nil)
      expect(event.slug).to eq("my-cool-event")
    end
  end

  describe "rejection_reason_templates" do
    it "defaults to empty array" do
      event = create(:event)
      expect(event.rejection_reason_templates).to eq([])
    end

    it "stores and retrieves templates" do
      event = create(:event, rejection_reason_templates: [ "Missing documents", "Invalid passport" ])
      expect(event.rejection_reason_templates_list).to eq([ "Missing documents", "Invalid passport" ])
    end

    it "validates templates must be array of strings" do
      event = build(:event, rejection_reason_templates: "not an array")
      expect(event).not_to be_valid
      expect(event.errors[:rejection_reason_templates]).to be_present
    end

    describe "#add_rejection_reason_template" do
      it "adds a new template" do
        event = create(:event)
        event.add_rejection_reason_template("New reason")
        expect(event.rejection_reason_templates_list).to include("New reason")
      end

      it "does not add duplicate templates" do
        event = create(:event, rejection_reason_templates: [ "Existing reason" ])
        result = event.add_rejection_reason_template("Existing reason")
        expect(result).to be false
        expect(event.rejection_reason_templates_list.count).to eq(1)
      end

      it "does not add blank templates" do
        event = create(:event)
        result = event.add_rejection_reason_template("")
        expect(result).to be false
      end
    end

    describe "#remove_rejection_reason_template" do
      it "removes an existing template" do
        event = create(:event, rejection_reason_templates: [ "Reason 1", "Reason 2" ])
        event.remove_rejection_reason_template("Reason 1")
        expect(event.rejection_reason_templates_list).to eq([ "Reason 2" ])
      end
    end
  end
end
