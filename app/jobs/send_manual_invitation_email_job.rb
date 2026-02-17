class SendManualInvitationEmailJob < ApplicationJob
  queue_as :default

  def perform(invitation_id)
    invitation = ManualInvitation.find_by(id: invitation_id)
    return if invitation.nil?
    return if invitation.claimed?

    ApplicationMailer.manual_invitation(invitation).deliver_now
  end
end
