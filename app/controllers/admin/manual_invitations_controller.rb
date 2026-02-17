class Admin::ManualInvitationsController < Admin::BaseController
  def index
    @invitations = policy_scope(ManualInvitation)
                    .includes(:event, :admin, :visa_letter_application)
                    .order(created_at: :desc)

    if params[:status] == "pending"
      @invitations = @invitations.pending
    elsif params[:status] == "claimed"
      @invitations = @invitations.claimed
    end

    if params[:event_id].present?
      @invitations = @invitations.where(event_id: params[:event_id])
    end

    @invitations = @invitations.page(params[:page]).per(25) if @invitations.respond_to?(:page)
  end

  def new
    @invitation = ManualInvitation.new
    authorize @invitation
    @events = policy_scope(Event).order(:name)
  end

  def create
    @invitation = ManualInvitation.new(invitation_params)
    @invitation.admin = current_admin
    authorize @invitation

    if @invitation.save
      SendManualInvitationEmailJob.perform_later(@invitation.id)

      ActivityLog.log!(
        trackable: @invitation.event,
        action: "manual_invitation_created",
        admin: current_admin,
        metadata: { email: @invitation.email, invitation_id: @invitation.id },
        request: request
      )

      redirect_to admin_manual_invitations_path,
                  notice: "Invitation sent to #{@invitation.email} for #{@invitation.event.name}."
    else
      @events = policy_scope(Event).order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def invitation_params
    params.require(:manual_invitation).permit(:email, :event_id)
  end
end
