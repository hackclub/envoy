class Admin::EventsController < Admin::BaseController
    before_action :set_event, only: [ :show, :edit, :update, :destroy ]

    def index
      @events = policy_scope(Event).order(start_date: :desc)
    end

    def show
      authorize @event
      @applications = @event.visa_letter_applications.includes(:participant).order(created_at: :desc)
    end

    def new
      @event = Event.new
      authorize @event
    end

    def create
      @event = current_admin.events.build(event_params)
      authorize @event

      if @event.save
        ActivityLog.log!(
          trackable: @event,
          action: "event_created",
          admin: current_admin,
          request: request
        )
        redirect_to admin_event_path(@event), notice: "Event was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @event
    end

    def update
      authorize @event

      if @event.update(event_params)
        ActivityLog.log!(
          trackable: @event,
          action: "event_updated",
          admin: current_admin,
          metadata: { changes: @event.previous_changes },
          request: request
        )
        redirect_to admin_event_path(@event), notice: "Event was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @event

      if @event.visa_letter_applications.exists?
        redirect_to admin_events_path, alert: "Cannot delete event with existing applications."
      else
        @event.destroy
        ActivityLog.log!(
          trackable: @event,
          action: "event_deleted",
          admin: current_admin,
          request: request
        )
        redirect_to admin_events_path, notice: "Event was successfully deleted."
      end
    end

    private

    def set_event
      @event = Event.find(params[:id])
    end

    def event_params
      permitted = [
        :name, :slug, :description, :venue_name, :venue_address,
        :city, :country, :start_date, :end_date, :application_deadline,
        :contact_email, :active, :applications_open,
        rejection_reason_templates: []
      ]
      permitted << :admin_id if current_admin.super_admin?
      result = params.require(:event).permit(permitted)
      if result[:rejection_reason_templates].present?
        result[:rejection_reason_templates] = result[:rejection_reason_templates].reject(&:blank?)
      end
      result
    end
end
