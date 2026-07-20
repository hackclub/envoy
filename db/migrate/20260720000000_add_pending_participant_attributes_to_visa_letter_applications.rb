class AddPendingParticipantAttributesToVisaLetterApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :visa_letter_applications, :pending_participant_attributes, :jsonb
  end
end
