class AdminMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM_ADDRESS", "noreply@hackclub.com") }
  layout "mailer"

  def new_application_notification(application)
    @application = application
    @participant = application.participant
    @event = application.event

    recipients = []

    # Add event owner if they want notifications
    event_owner = @event.admin
    if event_owner.notify_new_applications?
      recipients << event_owner.email
    end

    # Add super admins who want notifications
    recipients += Admin.where(super_admin: true, notify_new_applications: true).pluck(:email)

    recipients = recipients.uniq.compact

    return if recipients.empty?

    mail(
      to: recipients,
      subject: "New Visa Letter Application - #{@event.name}"
    )
  end

  def daily_summary(admin)
    @admin = admin
    @today = Date.current
    @new_applications = VisaLetterApplication.where("created_at >= ?", @today.beginning_of_day).count
    @pending_applications = VisaLetterApplication.pending_approval.count
    @approved_today = VisaLetterApplication.where(status: "approved").where("reviewed_at >= ?", @today.beginning_of_day).count
    @rejected_today = VisaLetterApplication.where(status: "rejected").where("reviewed_at >= ?", @today.beginning_of_day).count

    mail(
      to: admin.email,
      subject: "Daily Visa Letter Application Summary - #{@today.strftime('%B %d, %Y')}"
    )
  end
end
