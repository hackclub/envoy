class ApplicationApprovalService
  def initialize(application, admin)
    @application = application
    @admin = admin
  end

  def approve!(notes: nil)
    return { success: false, error: "Application cannot be approved" } unless @application.can_be_approved?

    ActiveRecord::Base.transaction do
      @application.approve!(@admin, notes: notes)

      ActivityLog.log!(
        trackable: @application,
        action: "approved",
        admin: @admin,
        metadata: { notes: notes }
      )
    end

    GenerateAndSendLetterJob.perform_later(@application.id)

    { success: true }
  rescue StandardError => e
    Rails.logger.error("Failed to approve application: #{e.message}")
    { success: false, error: e.message }
  end

  def reject!(reason:, rejection_type:, notes: nil)
    return { success: false, error: "Application cannot be rejected" } unless @application.can_be_rejected?

    ActiveRecord::Base.transaction do
      @application.reject!(@admin, reason: reason, rejection_type: rejection_type, notes: notes)

      ActivityLog.log!(
        trackable: @application,
        action: "rejected",
        admin: @admin,
        metadata: { reason: reason, rejection_type: rejection_type, notes: notes }
      )
    end

    SendRejectionNotificationJob.perform_later(@application.id)

    { success: true }
  rescue StandardError => e
    Rails.logger.error("Failed to reject application: #{e.message}")
    { success: false, error: e.message }
  end

  def downgrade_to_soft_reject!
    return { success: false, error: "Only hard-rejected applications can be downgraded" } unless @application.hard_rejected?

    ActiveRecord::Base.transaction do
      @application.downgrade_to_soft_reject!(@admin)

      ActivityLog.log!(
        trackable: @application,
        action: "downgraded_to_soft_reject",
        admin: @admin,
        metadata: {}
      )
    end

    SendRejectionDowngradeNotificationJob.perform_later(@application.id)

    { success: true }
  rescue StandardError => e
    Rails.logger.error("Failed to downgrade rejection: #{e.message}")
    { success: false, error: e.message }
  end
end
