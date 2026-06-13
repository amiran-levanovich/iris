require "rails_helper"

RSpec.describe Reservation, type: :model do
  describe "validations" do
    it "is valid with the factory defaults" do
      expect(build(:reservation)).to be_valid
    end

    it "requires check-out to be after check-in" do
      reservation = build(:reservation, check_in_on: Date.new(2026, 6, 5), check_out_on: Date.new(2026, 6, 5))

      expect(reservation).not_to be_valid
      expect(reservation.errors[:check_out_on]).to be_present
    end

    it "rejects a negative nightly rate" do
      expect(build(:reservation, nightly_rate_cents: -1)).not_to be_valid
    end
  end

  describe "lifecycle" do
    it "starts booked" do
      expect(build(:reservation)).to be_booked
    end

    it "walks booked -> checked_in -> checked_out" do
      reservation = create(:reservation)

      reservation.check_in!
      expect(reservation.reload).to be_checked_in

      reservation.check_out!
      expect(reservation.reload).to be_checked_out
    end

    it "cancels from booked" do
      reservation = create(:reservation)

      reservation.cancel!
      expect(reservation.reload).to be_cancelled
    end

    it "refuses to check out a reservation that never checked in" do
      reservation = create(:reservation)

      expect { reservation.check_out! }.to raise_error(AASM::InvalidTransition)
    end

    it "refuses to cancel an in-house reservation" do
      reservation = create(:reservation, :checked_in)

      expect { reservation.cancel! }.to raise_error(AASM::InvalidTransition)
    end
  end

  describe ".overlapping" do
    let(:room) { create(:room) }
    let(:period) { StayPeriod.new(check_in: Date.new(2026, 6, 10), check_out: Date.new(2026, 6, 15)) }

    it "matches a booked reservation that overlaps" do
      reservation = create(:reservation, room: room, check_in_on: Date.new(2026, 6, 12), check_out_on: Date.new(2026, 6, 18))

      expect(room.reservations.overlapping(period)).to include(reservation)
    end

    it "ignores a back-to-back reservation (half-open)" do
      create(:reservation, room: room, check_in_on: Date.new(2026, 6, 15), check_out_on: Date.new(2026, 6, 20))

      expect(room.reservations.overlapping(period)).to be_empty
    end

    it "ignores cancelled and checked-out reservations" do
      create(:reservation, :cancelled, room: room, check_in_on: Date.new(2026, 6, 11), check_out_on: Date.new(2026, 6, 14))
      create(:reservation, :checked_out, room: room, check_in_on: Date.new(2026, 6, 11), check_out_on: Date.new(2026, 6, 14))

      expect(room.reservations.overlapping(period)).to be_empty
    end
  end

  describe "#total_cents" do
    it "multiplies the nightly rate by the number of nights" do
      reservation = build(:reservation, nightly_rate_cents: 10_000,
                          check_in_on: Date.new(2026, 6, 1), check_out_on: Date.new(2026, 6, 4))

      expect(reservation.total_cents).to eq(30_000)
    end
  end
end
