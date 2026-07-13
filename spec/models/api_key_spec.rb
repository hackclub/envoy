require "rails_helper"

RSpec.describe ApiKey, type: :model do
  describe "token generation" do
    it "generates a prefixed token on create and stores only the digest" do
      api_key = create(:api_key)

      expect(api_key.token).to start_with(ApiKey::TOKEN_PREFIX)
      expect(api_key.token_digest).to eq(ApiKey.digest(api_key.token))
      expect(api_key.token_digest).not_to include(api_key.token)
    end

    it "does not expose the token after reload" do
      api_key = create(:api_key)
      expect(described_class.find(api_key.id).token).to be_nil
    end
  end

  describe ".authenticate" do
    it "returns the key for a valid token" do
      api_key = create(:api_key)
      expect(described_class.authenticate(api_key.token)).to eq(api_key)
    end

    it "returns nil for a blank or unknown token" do
      expect(described_class.authenticate(nil)).to be_nil
      expect(described_class.authenticate("")).to be_nil
      expect(described_class.authenticate("envoy_unknown")).to be_nil
    end

    it "returns nil for a revoked key" do
      api_key = create(:api_key)
      api_key.revoke!
      expect(described_class.authenticate(api_key.token)).to be_nil
    end
  end

  describe "#revoke!" do
    it "marks the key as revoked" do
      api_key = create(:api_key)
      expect { api_key.revoke! }.to change(api_key, :revoked?).from(false).to(true)
    end
  end
end
