class AdminMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM_ADDRESS", "noreply@hackclub.com") }
  layout "mailer"

  def new_application_notification(application)
    @application = application
    @participant = application.participant
    @event = application.event

    # The event owner, additional event admins, and super admins are all
    # candidates. Each decides per-event whether they want new-application
    # emails (see Admin#notify_new_applications_for?).
    candidate_admins = ([ @event.admin ] + @event.additional_admins.to_a + Admin.where(super_admin: true).to_a).uniq

    recipients = candidate_admins
                 .select { |admin| admin.notify_new_applications_for?(@event) }
                 .map(&:email)
                 .uniq
                 .compact

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
