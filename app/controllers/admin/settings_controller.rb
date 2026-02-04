class Admin::SettingsController < Admin::BaseController
  skip_after_action :verify_authorized

  def show
    @admin = current_admin
  end

  def update
    @admin = current_admin

    if @admin.update(settings_params)
      redirect_to admin_settings_path, notice: "Settings updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:admin).permit(:notify_new_applications)
  end
end
