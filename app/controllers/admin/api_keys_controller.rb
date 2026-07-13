class Admin::ApiKeysController < Admin::BaseController
  def index
    authorize ApiKey
    @api_keys = policy_scope(ApiKey).includes(:admin, :created_by).order(created_at: :desc)
    @api_key = ApiKey.new
    @admins = Admin.order(:last_name, :first_name)
  end

  def create
    @api_key = ApiKey.new(api_key_params.merge(created_by: current_admin))
    authorize @api_key

    if @api_key.save
      ActivityLog.log!(
        trackable: @api_key,
        action: "api_key_created",
        admin: current_admin,
        request: request
      )
      # Shown once on the index page; only the digest is stored.
      flash[:api_key_token] = @api_key.token
      redirect_to admin_api_keys_path, notice: "API key was successfully created. Copy the token now — it won't be shown again."
    else
      redirect_to admin_api_keys_path, alert: @api_key.errors.full_messages.to_sentence
    end
  end

  def destroy
    @api_key = ApiKey.find(params[:id])
    authorize @api_key

    @api_key.revoke!
    ActivityLog.log!(
      trackable: @api_key,
      action: "api_key_revoked",
      admin: current_admin,
      request: request
    )
    redirect_to admin_api_keys_path, notice: "API key was revoked."
  end

  private

  def api_key_params
    params.require(:api_key).permit(:name, :admin_id)
  end
end
