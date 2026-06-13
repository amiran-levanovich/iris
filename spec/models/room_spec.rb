require "rails_helper"

RSpec.describe Room, type: :model do
  describe "validations" do
    it "is valid with the factory defaults" do
      expect(build(:room)).to be_valid
    end

    it "requires a number" do
      room = build(:room, number: nil)

      expect(room).not_to be_valid
      expect(room.errors[:number]).to be_present
    end

    context "when a number is taken within the same property" do
      it "rejects the duplicate" do
        existing = create(:room, number: "101")
        duplicate = build(:room, property: existing.property, number: "101")

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:number]).to be_present
      end

      it "allows the same number in another property" do
        create(:room, number: "101")

        expect(build(:room, number: "101")).to be_valid
      end
    end

    it "requires a positive capacity" do
      expect(build(:room, capacity: 0)).not_to be_valid
      expect(build(:room, capacity: 1)).to be_valid
    end

    it "rejects a negative nightly rate" do
      expect(build(:room, nightly_rate_cents: -1)).not_to be_valid
      expect(build(:room, nightly_rate_cents: 0)).to be_valid
    end

    it "rejects an unknown room type" do
      expect { build(:room, room_type: "igloo") }.to raise_error(ArgumentError)
    end
  end

  describe "#change_status!" do
    it "transitions between statuses" do
      room = create(:room)

      room.change_status!("cleaning")
      expect(room.reload).to be_cleaning

      room.change_status!("out_of_service")
      expect(room.reload).to be_out_of_service

      room.change_status!("operational")
      expect(room.reload).to be_operational
    end

    it "raises on an unknown status" do
      room = create(:room)

      expect { room.change_status!("on_fire") }.to raise_error(ArgumentError)
      expect(room.reload).to be_operational
    end
  end

  describe "defaults" do
    it "starts operational" do
      expect(create(:room)).to be_operational
    end
  end

  describe ".available_between" do
    let(:period) { StayPeriod.new(check_in: Date.new(2026, 6, 10), check_out: Date.new(2026, 6, 15)) }

    it "includes a free operational room" do
      room = create(:room)

      expect(Room.available_between(period)).to include(room)
    end

    it "excludes an out-of-service room" do
      room = create(:room, :out_of_service)

      expect(Room.available_between(period)).not_to include(room)
    end

    it "includes a cleaning room (still bookable)" do
      room = create(:room, :cleaning)

      expect(Room.available_between(period)).to include(room)
    end

    it "excludes a room with an overlapping reservation" do
      room = create(:room)
      create(:reservation, room: room, check_in_on: Date.new(2026, 6, 12), check_out_on: Date.new(2026, 6, 18))

      expect(Room.available_between(period)).not_to include(room)
    end
  end

  describe "#current_reservation" do
    it "returns the checked-in reservation" do
      room = create(:room)
      stay = create(:reservation, :checked_in, room: room)
      create(:reservation, :cancelled, room: room)

      expect(room.current_reservation).to eq(stay)
    end
  end
end
