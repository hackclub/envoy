class AddPrivateToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :private, :boolean, default: false, null: false
  end
end
