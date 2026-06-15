require "rails_helper"

RSpec.describe Reservations::CheckOut do
  it "checks the reservation out and flips its room to cleaning" do
    room = create(:room, status: "operational")
    reservation = create(:reservation, :checked_in, room: room)

    described_class.call(reservation: reservation)

    expect(reservation.reload).to be_checked_out
    expect(room.reload).to be_cleaning
  end

  it "keeps the room out of service when it has an active maintenance request" do
    room = create(:room, status: "out_of_service")
    create(:maintenance_request, room: room)
    reservation = create(:reservation, :checked_in, room: room)

    described_class.call(reservation: reservation)

    expect(reservation.reload).to be_checked_out
    expect(room.reload).to be_out_of_service
  end

  it "raises and leaves the room untouched when the reservation cannot check out" do
    room = create(:room, status: "operational")
    reservation = create(:reservation, room: room) # still booked, never checked in

    expect {
      described_class.call(reservation: reservation)
    }.to raise_error(AASM::InvalidTransition)

    expect(reservation.reload).to be_booked
    expect(room.reload).to be_operational
  end
end
