class SendRejectionDowngradeNotificationJob < ApplicationJob
  queue_as :default

  def perform(application_id)
    application = VisaLetterApplication.find_by(id: application_id)
    return if application.nil?
    return unless application.soft_rejected?

    ApplicationMailer.rejection_downgraded(application).deliver_now

    ActivityLog.log!(
      trackable: application,
      action: "rejection_downgrade_notification_sent",
      metadata: { reference_number: application.reference_number }
    )
  end
end
