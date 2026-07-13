class Api::V1::AdminsController < Api::V1::BaseController
  def create
    @admin = Admin.new(admin_params)
    authorize @admin

    if @admin.save
      ActivityLog.log!(
        trackable: @admin,
        action: "admin_created",
        admin: current_admin,
        metadata: { via: "api", api_key_id: current_api_key.id },
        request: request
      )
      render json: admin_json(@admin), status: :created
    else
      render json: { errors: @admin.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def admin_params
    params.require(:admin).permit(:first_name, :last_name, :email, :super_admin, :notify_new_applications)
  end

  def admin_json(admin)
    admin.as_json(only: [
      :id, :first_name, :last_name, :email, :super_admin,
      :notify_new_applications, :created_at, :updated_at
    ])
  end
end
