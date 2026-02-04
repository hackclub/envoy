class AddEmailNotificationsToAdmins < ActiveRecord::Migration[8.1]
  def change
    add_column :admins, :notify_new_applications, :boolean, default: true, null: false
  end
end
