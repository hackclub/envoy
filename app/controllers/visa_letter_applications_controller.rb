class VisaLetterApplicationsController < ApplicationController
  before_action :set_event, only: [ :new, :create ]
  before_action :set_application, only: [ :show ]

  def new
    unless @event.accepting_applications?
      redirect_to events_path, alert: "This event is no longer accepting applications."
      return
    end

    @participant = Participant.new
  end

  def create
    unless @event.accepting_applications?
      redirect_to events_path, alert: "This event is no longer accepting applications."
      return
    end

    email = participant_params[:email].to_s.strip.downcase

    if VisaLetterApplication.email_hard_rejected_for_event?(email, @event)
      @participant = Participant.new(participant_params)
      flash.now[:alert] = "This email address is not eligible to apply for this event. If you believe this is an error, please contact #{@event.contact_email}."
      render :new, status: :unprocessable_entity
      return
    end

    existing_participant = Participant.find_by(email: email)

    if existing_participant
      existing_application = existing_participant.visa_letter_applications.find_by(event: @event)

      if existing_application && !existing_application.rejected?
        @participant = Participant.new(participant_params)
        flash.now[:alert] = "An application for this email already exists for this event. Please check your email for status updates."
        render :new, status: :unprocessable_entity
        return
      end

      existing_application&.destroy if existing_application&.soft_rejected?
    end

    @participant = existing_participant || Participant.new
    @participant.assign_attributes(participant_params)

    if @participant.save
      @application = @participant.visa_letter_applications.build(event: @event)

      if @application.save
        @participant.generate_verification_code!
        SendVerificationEmailJob.perform_later(@participant.id)

        ActivityLog.log!(
          trackable: @application,
          action: "application_created",
          metadata: { event_id: @event.id, participant_email: @participant.email },
          request: request
        )

        redirect_to verify_email_visa_letter_application_path(@application)
      else
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @participant = @application.participant
    @event = @application.event
  end

  def verify_email
    @application = VisaLetterApplication.find(params[:id])
    @participant = @application.participant
  end

  def confirm_verification
    @application = VisaLetterApplication.find(params[:id])
    @participant = @application.participant

    if @participant.verification_attempts_exceeded?
      flash.now[:alert] = "Too many failed attempts. Please request a new verification code."
      render :verify_email, status: :unprocessable_entity
      return
    end

    if @participant.verify_code!(params[:verification_code])
      @application.mark_as_submitted!

      ActivityLog.log!(
        trackable: @application,
        action: "email_verified",
        metadata: { participant_email: @participant.email },
        request: request
      )

      ApplicationMailer.application_submitted(@application).deliver_later
      AdminMailer.new_application_notification(@application).deliver_later

      redirect_to visa_letter_application_path(@application),
                  notice: "Your email has been verified and your application has been submitted!"
    else
      flash.now[:alert] = if @participant.verification_code_expired?
                            "Your verification code has expired. Please request a new one."
      else
                            "Invalid verification code. Please try again."
      end
      render :verify_email, status: :unprocessable_entity
    end
  end

  def resend_verification
    @application = VisaLetterApplication.find(params[:id])
    @participant = @application.participant

    if @participant.can_resend_verification_code?
      @participant.generate_verification_code!
      SendVerificationEmailJob.perform_later(@participant.id)
      redirect_to verify_email_visa_letter_application_path(@application),
                  notice: "A new verification code has been sent to your email."
    else
      redirect_to verify_email_visa_letter_application_path(@application),
                  alert: "Please wait before requesting a new code."
    end
  end

  def resend_letter
    @application = VisaLetterApplication.find(params[:id])

    unless @application.letter_sent?
      redirect_to visa_letter_application_path(@application), alert: "Letter has not been sent yet."
      return
    end

    ApplicationMailer.visa_letter_approved(@application).deliver_later

    redirect_to visa_letter_application_path(@application),
                notice: "Visa letter has been resent to #{@application.participant.email}."
  end

  def download_letter
    @application = VisaLetterApplication.find(params[:id])
    token = params[:token]

    unless token.present? && ActiveSupport::SecurityUtils.secure_compare(token, @application.verification_code)
      redirect_to root_path, alert: "Invalid or expired download link."
      return
    end

    unless @application.letter_pdf.attached?
      redirect_to root_path, alert: "Letter not available."
      return
    end

    send_data @application.letter_pdf.download,
              filename: "visa_letter_#{@application.reference_number}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

  def lookup
  end

  def find
    @application = VisaLetterApplication.find_by(reference_number: params[:reference_number]&.upcase)

    if @application
      redirect_to visa_letter_application_path(@application)
    else
      flash.now[:alert] = "Application not found. Please check your reference number."
      render :lookup, status: :not_found
    end
  end

  private

  def set_event
    @event = Event.find_by!(slug: params[:event_slug])
  end

  def set_application
    @application = VisaLetterApplication.find(params[:id])
  end

  def participant_params
    params.require(:participant).permit(
      :email, :full_name, :date_of_birth, :place_of_birth, :country_of_birth,
      :phone_number, :full_street_address
    )
  end
end
