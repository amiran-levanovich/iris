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
