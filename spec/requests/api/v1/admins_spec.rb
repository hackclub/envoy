require "rails_helper"

RSpec.describe "Api::V1::Admins", type: :request do
  let(:super_admin) { create(:admin, :super_admin) }
  let(:super_key) { create(:api_key, admin: super_admin) }

  let(:valid_params) do
    { admin: { first_name: "New", last_name: "Admin", email: "new-admin@hackclub.com" } }
  end

  def post_admin(params, token)
    post "/api/v1/admins", params: params.to_json,
      headers: { "Content-Type" => "application/json", "Authorization" => "Bearer #{token}" }
  end

  describe "POST /api/v1/admins" do
    it "returns 401 without an API key" do
      post "/api/v1/admins", params: valid_params.to_json, headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 403 for a non-super-admin key" do
      regular_key = create(:api_key, admin: create(:admin))

      expect { post_admin(valid_params, regular_key.token) }.not_to change(Admin, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it "creates an admin with a super admin key" do
      token = super_key.token
      expect { post_admin(valid_params, token) }.to change(Admin, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["email"]).to eq("new-admin@hackclub.com")
      expect(body["super_admin"]).to be(false)
    end

    it "can create a super admin" do
      post_admin({ admin: valid_params[:admin].merge(super_admin: true) }, super_key.token)

      expect(JSON.parse(response.body)["super_admin"]).to be(true)
    end

    it "logs the creation with the API key id" do
      post_admin(valid_params, super_key.token)

      log = ActivityLog.find_by(action: "admin_created", admin: super_admin)
      expect(log.metadata).to include("via" => "api", "api_key_id" => super_key.id)
    end

    it "returns validation errors for duplicate emails" do
      create(:admin, email: "new-admin@hackclub.com")
      post_admin(valid_params, super_key.token)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("Email has already been taken")
    end
  end
end
