class CreateEventAdmins < ActiveRecord::Migration[8.1]
  def change
    create_table :event_admins, id: :uuid do |t|
      t.references :event, null: false, foreign_key: true, type: :uuid
      t.references :admin, null: false, foreign_key: true, type: :uuid
      t.timestamps
    end

    add_index :event_admins, [:event_id, :admin_id], unique: true
  end
end
