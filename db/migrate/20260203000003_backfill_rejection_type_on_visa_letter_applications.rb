class BackfillRejectionTypeOnVisaLetterApplications < ActiveRecord::Migration[8.1]
  def up
    # Set existing rejected applications to soft reject by default
    execute <<-SQL
      UPDATE visa_letter_applications
      SET rejection_type = 'soft'
      WHERE status = 'rejected' AND rejection_type IS NULL
    SQL
  end

  def down
    # No-op, we don't want to remove the data
  end
end
