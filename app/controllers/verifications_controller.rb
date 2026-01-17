class VerificationsController < ApplicationController
  def show
    @verification_code = params[:code]
    @application = VisaLetterApplication.find_by(verification_code: @verification_code) if @verification_code.present?
  end

  def verify
    @verification_code = params[:code]&.strip&.upcase
    @application = VisaLetterApplication.find_by(verification_code: @verification_code)

    if @application && @application.letter_sent?
      render :verified
    elsif @application
      render :pending
    else
      flash.now[:alert] = "Invalid verification code. Please check and try again."
      render :show, status: :unprocessable_entity
    end
  end
end
