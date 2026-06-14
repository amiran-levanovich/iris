require "rails_helper"

RSpec.describe "Rooms", type: :request do
  let(:user) { create(:user) }
  let(:property) { create(:property) }

  before { sign_in(user) }

  describe "GET /properties/:property_id/rooms" do
    it "renders the housekeeping dashboard with occupancy" do
      room = create(:room, property: property, number: "101")
      guest = create(:guest, first_name: "Ada", last_name: "Lovelace")
      create(:reservation, :checked_in, room: room, guest: guest)

      get property_rooms_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("101").and include("Ada Lovelace")
    end
  end

  describe "POST /properties/:property_id/rooms" do
    context "with valid params" do
      it "creates the room through its property and redirects" do
        expect {
          post property_rooms_path(property),
               params: { room: { number: "101", room_type: "double", capacity: 2, nightly_rate_cents: 9_000 } }
        }.to change(property.rooms, :count).by(1)

        expect(response).to redirect_to(property_rooms_path(property))
      end
    end

    context "with an unknown room type" do
      it "re-renders the form instead of raising" do
        expect {
          post property_rooms_path(property),
               params: { room: { number: "101", room_type: "igloo", capacity: 2, nightly_rate_cents: 9_000 } }
        }.not_to change(Room, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with a duplicate number in the property" do
      it "re-renders the form with errors" do
        create(:room, property: property, number: "101")

        expect {
          post property_rooms_path(property),
               params: { room: { number: "101", room_type: "double", capacity: 2, nightly_rate_cents: 9_000 } }
        }.not_to change(Room, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /rooms/:id" do
    let(:room) { create(:room, property: property) }

    context "with valid params" do
      it "updates the room and redirects to its property" do
        patch room_path(room), params: { room: { capacity: 4 } }

        expect(room.reload.capacity).to eq(4)
        expect(response).to redirect_to(property_rooms_path(property))
      end
    end

    context "with invalid params" do
      it "re-renders the form with errors" do
        patch room_path(room), params: { room: { capacity: 0 } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /rooms/:id/status" do
    let(:room) { create(:room, property: property) }

    it "transitions the room status and redirects to the property" do
      patch status_room_path(room), params: { status: "cleaning" }

      expect(room.reload).to be_cleaning
      expect(response).to redirect_to(property_rooms_path(property))
    end

    it "rejects an unknown status without changing the room" do
      patch status_room_path(room), params: { status: "on_fire" }

      expect(room.reload).to be_operational
      expect(response).to redirect_to(property_rooms_path(property))
      expect(flash[:alert]).to be_present
    end
  end
end
