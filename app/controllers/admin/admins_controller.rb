class Admin::AdminsController < Admin::BaseController
  before_action :set_admin, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize Admin
    @admins = policy_scope(Admin).order(:last_name, :first_name)
  end

  def show
    authorize @admin
  end

  def new
    @admin = Admin.new
    authorize @admin
  end

  def create
    @admin = Admin.new(admin_params)
    authorize @admin

    if @admin.save
      ActivityLog.log!(
        trackable: @admin,
        action: "admin_created",
        admin: current_admin,
        request: request
      )
      redirect_to admin_admins_path, notice: "Admin was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @admin
  end

  def update
    authorize @admin

    update_params = admin_params
    update_params = update_params.except(:password, :password_confirmation) if update_params[:password].blank?

    if @admin.update(update_params)
      ActivityLog.log!(
        trackable: @admin,
        action: "admin_updated",
        admin: current_admin,
        metadata: { changes: @admin.previous_changes.except("encrypted_password", "updated_at") },
        request: request
      )
      redirect_to admin_admins_path, notice: "Admin was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @admin

    if @admin.events.exists?
      redirect_to admin_admins_path, alert: "Cannot delete admin with existing events."
    elsif @admin.reviewed_applications.exists?
      redirect_to admin_admins_path, alert: "Cannot delete admin who has reviewed applications."
    else
      @admin.destroy
      ActivityLog.log!(
        trackable: @admin,
        action: "admin_deleted",
        admin: current_admin,
        request: request
      )
      redirect_to admin_admins_path, notice: "Admin was successfully deleted."
    end
  end

  private

  def set_admin
    @admin = Admin.find(params[:id])
  end

  def admin_params
    permitted = [ :first_name, :last_name, :email, :password, :password_confirmation ]
    permitted << :super_admin if current_admin.super_admin?
    params.require(:admin).permit(permitted)
  end
end
