require "rails_helper"

RSpec.describe "Reservations", type: :request do
  let(:user) { create(:user) }
  let(:property) { create(:property) }
  let(:room) { create(:room, property: property) }
  let(:guest) { create(:guest) }

  before { sign_in(user) }

  def booking_params(overrides = {})
    {
      reservation: {
        guest_id: guest.id,
        room_id: room.id,
        check_in_on: "2026-06-10",
        check_out_on: "2026-06-13"
      }.merge(overrides)
    }
  end

  describe "GET /properties/:property_id/reservations" do
    it "renders the movements strip and the reservation list" do
      arriving = create(:reservation, room: room, guest: guest, check_in_on: Date.current, check_out_on: Date.current.next_day(2))

      get property_reservations_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Arrivals").and include(guest.name)
      expect(response.body).to include(arriving.internal_id)
    end

    it "narrows the list by reservation code, case-insensitively" do
      target = create(:reservation, room: room, guest: guest, internal_id: "AAAAAA")
      other = create(:reservation, room: room, guest: create(:guest), internal_id: "ZZZZZZ")

      get property_reservations_path(property), params: { q: "aaaaaa" }

      expect(response.body).to include(target.internal_id)
      expect(response.body).not_to include(other.internal_id)
    end

    it "filters by status" do
      checked = create(:reservation, :checked_in, room: room, guest: guest, internal_id: "CHKDIN")
      cancelled = create(:reservation, :cancelled, room: room, guest: create(:guest), internal_id: "CANCEL")

      get property_reservations_path(property), params: { status: "checked_in" }

      expect(response.body).to include(checked.internal_id)
      expect(response.body).not_to include(cancelled.internal_id)
    end
  end

  describe "GET /properties/:property_id/reservations/new" do
    it "renders the booking form with available rooms" do
      room

      get new_property_reservation_path(property), params: { check_in_on: "2026-06-10", check_out_on: "2026-06-13" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(room.number)
    end
  end

  describe "POST /properties/:property_id/reservations" do
    context "with valid params" do
      it "books the room and redirects to the property page" do
        expect {
          post property_reservations_path(property), params: booking_params
        }.to change(Reservation, :count).by(1)

        expect(response).to redirect_to(property_reservations_path(property))
        expect(Reservation.last.nightly_rate_cents).to eq(room.nightly_rate_cents)
      end
    end

    context "when the room is already booked for the dates" do
      it "re-renders the form without booking" do
        create(:reservation, room: room, guest: guest,
               check_in_on: Date.new(2026, 6, 11), check_out_on: Date.new(2026, 6, 14))

        expect {
          post property_reservations_path(property), params: booking_params
        }.not_to change(Reservation, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with an invalid date range" do
      it "re-renders the form" do
        expect {
          post property_reservations_path(property), params: booking_params(check_out_on: "2026-06-10")
        }.not_to change(Reservation, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when no guest is selected" do
      it "re-renders the form with an alert instead of raising" do
        expect {
          post property_reservations_path(property), params: booking_params(guest_id: "")
        }.not_to change(Reservation, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "PATCH /reservations/:id/check_in" do
    it "checks the guest in" do
      reservation = create(:reservation, room: room, guest: guest)

      patch check_in_reservation_path(reservation)

      expect(reservation.reload).to be_checked_in
      expect(response).to redirect_to(property_reservations_path(property))
    end
  end

  describe "PATCH /reservations/:id/check_out" do
    it "checks out and flips the room to cleaning" do
      reservation = create(:reservation, :checked_in, room: room, guest: guest)

      patch check_out_reservation_path(reservation)

      expect(reservation.reload).to be_checked_out
      expect(room.reload).to be_cleaning
      expect(response).to redirect_to(property_reservations_path(property))
    end

    context "when the reservation was never checked in" do
      it "redirects with an alert instead of raising" do
        reservation = create(:reservation, room: room, guest: guest)

        patch check_out_reservation_path(reservation)

        expect(reservation.reload).to be_booked
        expect(response).to redirect_to(property_reservations_path(property))
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "PATCH /reservations/:id/cancel" do
    it "cancels a booked reservation" do
      reservation = create(:reservation, room: room, guest: guest)

      patch cancel_reservation_path(reservation)

      expect(reservation.reload).to be_cancelled
      expect(response).to redirect_to(property_reservations_path(property))
    end
  end
end
