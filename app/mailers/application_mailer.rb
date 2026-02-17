class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM_ADDRESS", "noreply@hackclub.com") }
  layout "mailer"

  def verification_code(participant)
    @participant = participant
    @code = participant.verification_code

    mail(
      to: participant.email,
      subject: "Your Hack Club Visa Letter Verification Code"
    )
  end

  def application_submitted(application)
    @application = application
    @participant = application.participant
    @event = application.event

    mail(
      to: @participant.email,
      subject: "Your Visa Letter Application Has Been Submitted - #{@event.name}"
    )
  end

  def visa_letter_approved(application)
    @application = application
    @participant = application.participant
    @event = application.event
    @download_url = download_letter_visa_letter_application_url(
      application,
      token: application.verification_code
    )

    mail(
      to: @participant.email,
      subject: "Your Visa Letter is Ready - #{@event.name}"
    )
  end

  def application_rejected(application)
    @application = application
    @participant = application.participant
    @event = application.event
    @can_reapply = application.soft_rejected?
    @reapply_url = new_event_application_url(@event.slug) if @can_reapply

    mail(
      to: @participant.email,
      subject: "Update on Your Visa Letter Application - #{@event.name}"
    )
  end

  def manual_invitation(invitation)
    @invitation = invitation
    @event = invitation.event
    @apply_url = new_event_application_url(
      @event.slug,
      invitation: invitation.token
    )

    mail(
      to: invitation.email,
      subject: "You're Invited to Apply for a Visa Letter - #{@event.name}"
    )
  end

  def rejection_downgraded(application)
    @application = application
    @participant = application.participant
    @event = application.event
    @reapply_url = new_event_application_url(@event.slug)

    mail(
      to: @participant.email,
      subject: "You Can Now Reapply for Your Visa Letter - #{@event.name}"
    )
  end
end
