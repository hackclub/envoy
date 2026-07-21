require "rails_helper"

RSpec.describe "VisaLetterApplications", type: :request do
  describe "POST /events/:event_slug/apply" do
    context "when the email already belongs to an existing participant" do
      let!(:participant) { create(:participant, :verified) }
      let!(:event_a) { create(:event) }
      let!(:existing_application) do
        create(:visa_letter_application, :pending_approval, participant: participant, event: event_a)
      end
      let!(:event_b) { create(:event) }

      # Reuse the victim's email (never a literal) but supply fresh, synthetic
      # values for every other field, marked with sentinels we can assert on.
      let(:submitted_attrs) do
        attributes_for(:participant).merge(
          email: participant.email,
          full_name: "Submitted Sentinel Name",
          country_of_birth: "Canada"
        )
      end

      it "does not overwrite the participant's PII before email verification" do
        original_name = participant.full_name
        original_country = participant.country_of_birth

        expect {
          post event_applications_path(event_slug: event_b.slug), params: { participant: submitted_attrs }
        }.to change { VisaLetterApplication.count }.by(1)

        participant.reload
        expect(participant.full_name).to eq(original_name)
        expect(participant.country_of_birth).to eq(original_country)

        # The previously submitted application still reads the original identity.
        expect(existing_application.reload.participant.full_name).to eq(original_name)
      end

      it "holds the submitted attributes on the pending application" do
        post event_applications_path(event_slug: event_b.slug), params: { participant: submitted_attrs }

        new_application = participant.visa_letter_applications.find_by(event: event_b)
        expect(new_application).to be_present
        expect(new_application.pending_participant_attributes).to include(
          "full_name" => "Submitted Sentinel Name",
          "country_of_birth" => "Canada"
        )
        expect(new_application.pending_participant_attributes).not_to have_key("email")
      end

      it "applies the submitted PII only after the email is verified" do
        post event_applications_path(event_slug: event_b.slug), params: { participant: submitted_attrs }
        new_application = participant.visa_letter_applications.find_by(event: event_b)

        code = participant.reload.verification_code
        expect(code).to be_present

        post confirm_verification_visa_letter_application_path(new_application),
             params: { verification_code: code }

        participant.reload
        expect(participant.full_name).to eq("Submitted Sentinel Name")
        expect(participant.country_of_birth).to eq("Canada")

        new_application.reload
        expect(new_application.pending_participant_attributes).to be_nil
        expect(new_application).to be_pending_approval
      end
    end

    context "when the email is new" do
      let!(:event) { create(:event) }
      let(:new_attrs) { attributes_for(:participant).merge(full_name: "Newcomer Sentinel Name") }

      it "creates the participant and application, then routes to verification" do
        expect {
          post event_applications_path(event_slug: event.slug), params: { participant: new_attrs }
        }.to change { Participant.count }.by(1)
          .and change { VisaLetterApplication.count }.by(1)

        participant = Participant.find_by(email: new_attrs[:email])
        expect(participant.full_name).to eq("Newcomer Sentinel Name")
        expect(participant).not_to be_email_verified
      end
    end
  end
end
