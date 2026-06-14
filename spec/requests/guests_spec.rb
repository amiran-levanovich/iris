require "rails_helper"

RSpec.describe "Guests", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "GET /guests" do
    it "lists guests" do
      create(:guest, name: "Ada Lovelace")

      get guests_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ada Lovelace")
    end
  end

  describe "GET /guests?q= (booking picker search)" do
    it "returns only the picker results for a Turbo Frame request" do
      create(:guest, name: "Ada Lovelace")
      create(:guest, name: "Grace Hopper")

      get guests_path, params: { q: "ada" }, headers: { "Turbo-Frame" => "guest_results" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ada Lovelace").and include("guest-result")
      expect(response.body).not_to include("Grace Hopper")
    end
  end

  describe "POST /guests as turbo_stream (inline create)" do
    it "creates the guest and returns a stream selecting it" do
      expect {
        post guests_path, params: { guest: { name: "Inline Guest" } }, as: :turbo_stream
      }.to change(Guest, :count).by(1)

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("guest_selection").and include("Inline Guest")
    end
  end

  describe "POST /guests" do
    context "with valid params" do
      it "creates the guest and redirects to it" do
        expect {
          post guests_path, params: { guest: { name: "Grace Hopper", email: "grace@example.com" } }
        }.to change(Guest, :count).by(1)

        expect(response).to redirect_to(guest_path(Guest.last))
      end
    end

    context "with invalid params" do
      it "re-renders the form" do
        expect {
          post guests_path, params: { guest: { name: "" } }
        }.not_to change(Guest, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /guests/:id" do
    it "updates the guest" do
      guest = create(:guest)

      patch guest_path(guest), params: { guest: { name: "Renamed" } }

      expect(guest.reload.name).to eq("Renamed")
      expect(response).to redirect_to(guest_path(guest))
    end
  end
end
