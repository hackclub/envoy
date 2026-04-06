class EventsController < ApplicationController
  def index
    @events = Event.active.publicly_listed.accepting_applications.upcoming.order(:start_date)
  end

  def show
    @event = Event.active.find_by!(slug: params[:slug])
  end
end
