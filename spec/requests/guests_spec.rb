require "rails_helper"

RSpec.describe "Guests", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  def guest_attributes(overrides = {})
    {
      first_name: "Grace", last_name: "Hopper", email: "grace@example.com",
      street: "1 Main St", city: "Berlin", postal_code: "10115", country: "DE"
    }.merge(overrides)
  end

  describe "GET /guests" do
    it "lists guests" do
      create(:guest, first_name: "Ada", last_name: "Lovelace")

      get guests_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ada Lovelace")
    end
  end

  describe "GET /guests/:id back link" do
    let(:guest) { create(:guest) }

    it "returns to the referring page when it is same-origin" do
      get guest_path(guest), headers: { "HTTP_REFERER" => "http://www.example.com/properties/1/reservations" }

      expect(response.body).to include('href="/properties/1/reservations"')
    end

    it "falls back to the guests index without a referer" do
      get guest_path(guest)

      expect(response.body).to include(%(href="#{guests_path}"))
    end

    it "ignores a cross-origin referer" do
      get guest_path(guest), headers: { "HTTP_REFERER" => "http://evil.test/phish" }

      expect(response.body).not_to include("evil.test")
    end
  end

  describe "GET /guests?q= (booking picker search)" do
    it "returns only the picker results for a Turbo Frame request" do
      create(:guest, first_name: "Ada", last_name: "Lovelace")
      create(:guest, first_name: "Grace", last_name: "Hopper")

      get guests_path, params: { q: "ada" }, headers: { "Turbo-Frame" => "guest_results" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ada Lovelace").and include("guest-result")
      expect(response.body).not_to include("Grace Hopper")
    end
  end

  describe "POST /guests" do
    context "with valid params" do
      it "creates the guest and redirects to it" do
        expect {
          post guests_path, params: { guest: guest_attributes }
        }.to change(Guest, :count).by(1)

        expect(response).to redirect_to(guest_path(Guest.last))
      end

      it "persists the structured address" do
        post guests_path, params: { guest: guest_attributes(
          street: "5 Rustaveli Ave", city: "Tbilisi", postal_code: "0108", country: "GE"
        ) }

        expect(Guest.last).to have_attributes(street: "5 Rustaveli Ave", city: "Tbilisi",
                                              postal_code: "0108", country: "GE")
      end

      it "returns to the booking form with the new guest when return_to is given" do
        property = create(:property)

        post guests_path, params: {
          guest: guest_attributes,
          return_to: new_property_reservation_path(property, check_in_on: "2026-07-01", check_out_on: "2026-07-04")
        }

        expect(response).to redirect_to(
          new_property_reservation_path(property, check_in_on: "2026-07-01", check_out_on: "2026-07-04",
                                                  guest_id: Guest.last.id)
        )
      end

      it "ignores an off-site return_to (open-redirect guard)" do
        post guests_path, params: { guest: guest_attributes, return_to: "//evil.test/phish" }

        expect(response).to redirect_to(guest_path(Guest.last))
      end

      it "ignores the slash-backslash open-redirect variant" do
        post guests_path, params: { guest: guest_attributes, return_to: "/\\evil.test/phish" }

        expect(response).to redirect_to(guest_path(Guest.last))
      end
    end

    context "with missing required fields" do
      it "re-renders the form for a blank name" do
        expect {
          post guests_path, params: { guest: guest_attributes(first_name: "", last_name: "") }
        }.not_to change(Guest, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders the form for a missing address" do
        expect {
          post guests_path, params: { guest: guest_attributes(street: "", city: "", postal_code: "", country: "") }
        }.not_to change(Guest, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders the form for a missing email" do
        expect {
          post guests_path, params: { guest: guest_attributes(email: "") }
        }.not_to change(Guest, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /guests/new with picker prefill" do
    it "seeds the form from the typed name" do
      get new_guest_path, params: { guest: { first_name: "Amiran", last_name: "Tsiklauri" } }

      expect(response.body).to include("Amiran").and include("Tsiklauri")
    end
  end

  describe "PATCH /guests/:id" do
    it "updates the guest" do
      guest = create(:guest)

      patch guest_path(guest), params: { guest: { first_name: "Renamed" } }

      expect(guest.reload.first_name).to eq("Renamed")
      expect(response).to redirect_to(guest_path(guest))
    end
  end
end
