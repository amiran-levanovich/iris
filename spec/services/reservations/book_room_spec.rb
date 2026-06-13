require "rails_helper"

RSpec.describe Reservations::BookRoom do
  let(:room) { create(:room, nightly_rate_cents: 15_000) }
  let(:guest) { create(:guest) }
  let(:period) { StayPeriod.new(check_in: Date.new(2026, 6, 10), check_out: Date.new(2026, 6, 13)) }

  it "creates a booked reservation with a rate snapshot" do
    reservation = described_class.call(room: room, guest: guest, stay_period: period)

    expect(reservation).to be_persisted
    expect(reservation).to be_booked
    expect(reservation.nightly_rate_cents).to eq(15_000)
    expect(reservation.stay_period).to eq(period)
  end

  it "keeps the snapshot when the room rate later changes" do
    reservation = described_class.call(room: room, guest: guest, stay_period: period)

    room.update!(nightly_rate_cents: 20_000)

    expect(reservation.reload.nightly_rate_cents).to eq(15_000)
  end

  it "refuses an overlapping booking" do
    described_class.call(room: room, guest: guest, stay_period: period)
    overlap = StayPeriod.new(check_in: Date.new(2026, 6, 12), check_out: Date.new(2026, 6, 14))

    expect {
      described_class.call(room: room, guest: guest, stay_period: overlap)
    }.to raise_error(Reservations::RoomUnavailableError)
    expect(Reservation.count).to eq(1)
  end

  it "allows a back-to-back booking" do
    described_class.call(room: room, guest: guest, stay_period: period)
    adjacent = StayPeriod.new(check_in: Date.new(2026, 6, 13), check_out: Date.new(2026, 6, 16))

    expect {
      described_class.call(room: room, guest: guest, stay_period: adjacent)
    }.to change(Reservation, :count).by(1)
  end

  it "refuses to book an out-of-service room" do
    room.update!(status: "out_of_service")

    expect {
      described_class.call(room: room, guest: guest, stay_period: period)
    }.to raise_error(Reservations::RoomUnavailableError)
  end
end
