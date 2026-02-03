class Admin::VisaLetterApplicationsController < Admin::BaseController
    before_action :set_application, only: [ :show, :approve, :reject, :regenerate_letter, :downgrade_rejection ]

    def index
      @applications = policy_scope(VisaLetterApplication)
                      .includes(:participant, :event)
                      .order(created_at: :desc)

      if params[:status].present?
        @applications = @applications.where(status: params[:status])
      end

      if params[:event_id].present?
        @applications = @applications.where(event_id: params[:event_id])
      end

      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @applications = @applications.joins(:participant)
                                      .where("participants.full_name ILIKE :term OR participants.email ILIKE :term OR visa_letter_applications.reference_number ILIKE :term", term: search_term)
      end

      @applications = @applications.page(params[:page]).per(25) if @applications.respond_to?(:page)
    end

    def show
      authorize @application
      @participant = @application.participant
      @event = @application.event
      @activity_logs = ActivityLog.where(trackable: @application).order(created_at: :desc)
    end

    def approve
      authorize @application

      result = ApplicationApprovalService.new(@application, current_admin).approve!(
        notes: params[:admin_notes]
      )

      if result[:success]
        redirect_to admin_visa_letter_application_path(@application),
                    notice: "Application approved successfully. The visa letter will be generated and sent."
      else
        redirect_to admin_visa_letter_application_path(@application),
                    alert: "Failed to approve application: #{result[:error]}"
      end
    end

    def reject
      authorize @application

      if params[:rejection_reason].blank?
        redirect_to admin_visa_letter_application_path(@application),
                    alert: "Rejection reason is required."
        return
      end

      rejection_type = params[:rejection_type].presence || "soft"
      unless VisaLetterApplication::REJECTION_TYPES.include?(rejection_type)
        redirect_to admin_visa_letter_application_path(@application),
                    alert: "Invalid rejection type."
        return
      end

      result = ApplicationApprovalService.new(@application, current_admin).reject!(
        reason: params[:rejection_reason],
        rejection_type: rejection_type,
        notes: params[:admin_notes]
      )

      rejection_label = rejection_type == "hard" ? "permanently rejected" : "rejected (can reapply)"
      if result[:success]
        redirect_to admin_visa_letter_application_path(@application),
                    notice: "Application #{rejection_label}. The applicant will be notified."
      else
        redirect_to admin_visa_letter_application_path(@application),
                    alert: "Failed to reject application: #{result[:error]}"
      end
    end

    def downgrade_rejection
      authorize @application

      result = ApplicationApprovalService.new(@application, current_admin).downgrade_to_soft_reject!

      if result[:success]
        redirect_to admin_visa_letter_application_path(@application),
                    notice: "Rejection downgraded. The applicant can now reapply and will be notified."
      else
        redirect_to admin_visa_letter_application_path(@application),
                    alert: "Failed to downgrade rejection: #{result[:error]}"
      end
    end

    def regenerate_letter
      authorize @application

      unless @application.approved? || @application.letter_sent?
        redirect_to admin_visa_letter_application_path(@application),
                    alert: "Cannot regenerate letter for an application that is not approved."
        return
      end

      begin
        RegenerateAndSendLetterJob.perform_now(@application.id, current_admin.id)

        redirect_to admin_visa_letter_application_path(@application),
                    notice: "Letter has been regenerated and sent to #{@application.participant.email}."
      rescue StandardError => e
        Rails.logger.error("Failed to regenerate letter: #{e.message}")
        redirect_to admin_visa_letter_application_path(@application),
                    alert: "Failed to regenerate letter: #{e.message}"
      end
    end

    private

    def set_application
      @application = VisaLetterApplication.find(params[:id])
    end
end
