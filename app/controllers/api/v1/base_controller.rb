class Api::V1::BaseController < ActionController::API
  include Pundit::Authorization

  before_action :authenticate_api_key!

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: :bad_request
  end

  attr_reader :current_api_key, :current_admin

  def pundit_user
    current_admin
  end

  private

  def authenticate_api_key!
    token = request.headers["Authorization"]&.delete_prefix("Bearer ")
    @current_api_key = ApiKey.authenticate(token)

    if @current_api_key.nil?
      render json: { error: "Invalid or missing API key" }, status: :unauthorized
      return
    end

    @current_api_key.touch_last_used!
    @current_admin = @current_api_key.admin
  end

  def render_forbidden
    render json: { error: "You are not authorized to perform this action" }, status: :forbidden
  end

  def render_not_found
    render json: { error: "Not found" }, status: :not_found
  end
end
