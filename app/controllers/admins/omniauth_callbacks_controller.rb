class Admins::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # CSRF protection is intentionally left enabled here.
  #
  # * The request phase (admin_hack_club_omniauth_authorize_path) is a POST and
  #   is guarded by the omniauth-rails_csrf_protection gem plus the Rails form
  #   authenticity token.
  # * The callback below is reached via the provider's GET redirect (Hack Club
  #   OIDC uses the query response mode) and is protected against CSRF by the
  #   OAuth "state" parameter. Rails does not verify the authenticity token on
  #   GET requests, so no before_action needs to be skipped.

  def hack_club
    @admin = Admin.from_omniauth(request.env["omniauth.auth"])

    if @admin
      sign_in_and_redirect @admin, event: :authentication
      set_flash_message(:notice, :success, kind: "Hack Club") if is_navigational_format?
    else
      redirect_to root_path, alert: "You are not authorized to access the admin area."
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path, alert: "Authentication failed: #{e.message}"
  end

  def failure
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end
end
