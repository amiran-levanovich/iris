require "rails_helper"

RSpec.describe "Properties", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "GET /properties" do
    it "lists properties" do
      create(:property, name: "Hotel Adlon")

      get properties_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hotel Adlon")
    end

    context "when not signed in" do
      it "redirects to login" do
        delete session_path

        get properties_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /properties/:id" do
    it "shows the property with its rooms" do
      property = create(:property, name: "Hotel Adlon")
      create(:room, property: property, number: "101")

      get property_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hotel Adlon").and include("101")
    end

    it "leads with today's movements and shows occupancy on the room board" do
      property = create(:property)
      room = create(:room, property: property, number: "101")
      guest = create(:guest, name: "Ada Lovelace")
      create(:reservation, :checked_in, room: room, guest: guest,
             check_in_on: Date.current.prev_day, check_out_on: Date.current)

      get property_path(property)

      expect(response).to have_http_status(:ok)
      # In-house (checked in) and departing today, with the guest surfaced.
      expect(response.body).to include("In house").and include("Departures")
      expect(response.body).to include("Ada Lovelace").and include("101")
    end
  end

  describe "POST /properties" do
    context "with valid params" do
      it "creates the property and redirects to it" do
        expect {
          post properties_path, params: { property: { name: "Hotel Iris" } }
        }.to change(Property, :count).by(1)

        expect(response).to redirect_to(property_path(Property.last))
      end
    end

    context "with invalid params" do
      it "re-renders the form with errors" do
        expect {
          post properties_path, params: { property: { name: "" } }
        }.not_to change(Property, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /properties/:id" do
    let(:property) { create(:property) }

    context "with valid params" do
      it "updates the property and redirects" do
        patch property_path(property), params: { property: { name: "Renamed" } }

        expect(property.reload.name).to eq("Renamed")
        expect(response).to redirect_to(property_path(property))
      end
    end

    context "with invalid params" do
      it "re-renders the form with errors" do
        patch property_path(property), params: { property: { stars: 9 } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
