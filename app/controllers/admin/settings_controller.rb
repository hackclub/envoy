class Admin::SettingsController < Admin::BaseController
  skip_after_action :verify_authorized

  def show
    @admin = current_admin
    @events = notifiable_events
  end

  def update
    @admin = current_admin

    update_notification_preferences

    redirect_to admin_settings_path, notice: "Notification preferences updated successfully."
  end

  private

  def notifiable_events
    current_admin.notifiable_events.order(start_date: :desc, name: :asc)
  end

  def update_notification_preferences
    submitted = params.fetch(:notification_preferences, {}).to_unsafe_h
    allowed_event_ids = current_admin.notifiable_events.pluck(:id).to_set

    submitted.each do |event_id, value|
      next unless allowed_event_ids.include?(event_id)

      preference = current_admin.event_notification_preferences.find_or_initialize_by(event_id: event_id)
      preference.notify_new_applications = ActiveModel::Type::Boolean.new.cast(value)
      preference.save
    end
  end
end
