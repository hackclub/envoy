class CreateManualInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :manual_invitations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :email, null: false
      t.references :event, null: false, foreign_key: true, type: :uuid
      t.references :admin, null: false, foreign_key: true, type: :uuid
      t.string :token, null: false
      t.datetime :claimed_at
      t.references :visa_letter_application, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :manual_invitations, :token, unique: true
    add_index :manual_invitations, :email
  end
end
