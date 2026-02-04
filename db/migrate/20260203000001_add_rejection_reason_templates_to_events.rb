class AddRejectionReasonTemplatesToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :rejection_reason_templates, :jsonb, default: [], null: false
  end
end
