class CreateEventNotificationPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :event_notification_preferences, id: :uuid do |t|
      t.references :admin, null: false, foreign_key: true, type: :uuid
      t.references :event, null: false, foreign_key: true, type: :uuid
      t.boolean :notify_new_applications, null: false, default: true
      t.timestamps
    end

    add_index :event_notification_preferences, [ :admin_id, :event_id ], unique: true
  end
end
