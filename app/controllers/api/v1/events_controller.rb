class Api::V1::EventsController < Api::V1::BaseController
  def create
    @event = Event.new(event_params)
    @event.admin ||= current_admin
    authorize @event

    if @event.save
      ActivityLog.log!(
        trackable: @event,
        action: "event_created",
        admin: current_admin,
        metadata: { via: "api", api_key_id: current_api_key.id },
        request: request
      )
      render json: event_json(@event), status: :created
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def event_params
    permitted = [
      :name, :slug, :description, :venue_name, :venue_address,
      :city, :country, :start_date, :end_date, :application_deadline,
      :contact_email, :active, :applications_open, :private,
      rejection_reason_templates: []
    ]
    permitted << :admin_id if current_admin.super_admin?
    params.require(:event).permit(permitted)
  end

  def event_json(event)
    event.as_json(only: [
      :id, :name, :slug, :description, :venue_name, :venue_address,
      :city, :country, :start_date, :end_date, :application_deadline,
      :contact_email, :active, :applications_open, :private, :admin_id,
      :created_at, :updated_at
    ])
  end
end
