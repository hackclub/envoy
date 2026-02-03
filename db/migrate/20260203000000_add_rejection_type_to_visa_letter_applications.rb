class AddRejectionTypeToVisaLetterApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :visa_letter_applications, :rejection_type, :string
    add_index :visa_letter_applications, :rejection_type
  end
end
