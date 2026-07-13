require "rails_helper"

RSpec.describe "Api::V1::Events", type: :request do
  let(:admin) { create(:admin) }
  let(:api_key) { create(:api_key, admin: admin) }

  let(:valid_params) do
    {
      event: {
        name: "API Created Event",
        venue_name: "Convention Center",
        venue_address: "123 Main St",
        city: "Toronto",
        country: "Canada",
        start_date: 3.months.from_now.to_date,
        end_date: 3.months.from_now.to_date + 2.days,
        contact_email: "events@hackclub.com"
      }
    }
  end

  def post_event(params, token)
    post "/api/v1/events", params: params.to_json,
      headers: { "Content-Type" => "application/json", "Authorization" => "Bearer #{token}" }
  end

  describe "POST /api/v1/events" do
    it "returns 401 without an API key" do
      post "/api/v1/events", params: valid_params.to_json, headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with a revoked API key" do
      token = api_key.token
      api_key.revoke!
      post_event(valid_params, token)
      expect(response).to have_http_status(:unauthorized)
    end

    it "creates an event owned by the key's admin" do
      expect { post_event(valid_params, api_key.token) }.to change(Event, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("API Created Event")
      expect(body["admin_id"]).to eq(admin.id)
      expect(body["slug"]).to be_present
    end

    it "logs the creation with the API key id" do
      post_event(valid_params, api_key.token)

      log = ActivityLog.find_by(action: "event_created", admin: admin)
      expect(log.metadata).to include("via" => "api", "api_key_id" => api_key.id)
    end

    it "updates the key's last_used_at" do
      expect { post_event(valid_params, api_key.token) }
        .to change { api_key.reload.last_used_at }.from(nil)
    end

    it "returns validation errors for invalid params" do
      post_event({ event: { name: "Incomplete" } }, api_key.token)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("Venue name can't be blank")
    end

    it "ignores admin_id for non-super-admin keys" do
      other_admin = create(:admin)
      post_event({ event: valid_params[:event].merge(admin_id: other_admin.id) }, api_key.token)

      expect(JSON.parse(response.body)["admin_id"]).to eq(admin.id)
    end

    it "allows super admin keys to assign another owner" do
      super_key = create(:api_key, admin: create(:admin, :super_admin))
      other_admin = create(:admin)
      post_event({ event: valid_params[:event].merge(admin_id: other_admin.id) }, super_key.token)

      expect(JSON.parse(response.body)["admin_id"]).to eq(other_admin.id)
    end
  end
end
