require "rails_helper"

RSpec.describe Guest, type: :model do
  describe "validations" do
    it "is valid with the factory defaults" do
      expect(build(:guest)).to be_valid
    end

    it "requires a name" do
      guest = build(:guest, name: nil)

      expect(guest).not_to be_valid
      expect(guest.errors[:name]).to be_present
    end

    it "rejects a duplicate email" do
      create(:guest, email: "taken@example.com")
      duplicate = build(:guest, email: "taken@example.com")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end

    it "allows multiple guests without an email" do
      create(:guest, email: nil)

      expect(build(:guest, email: nil)).to be_valid
    end
  end

  describe ".search" do
    it "matches a partial name case-insensitively" do
      ada = create(:guest, name: "Ada Lovelace")
      create(:guest, name: "Grace Hopper")

      expect(Guest.search("lovel")).to contain_exactly(ada)
      expect(Guest.search("ADA")).to contain_exactly(ada)
    end
  end

  describe "#reservations" do
    it "lists stays newest check-in first" do
      guest = create(:guest)
      older = create(:reservation, guest: guest, check_in_on: Date.new(2026, 1, 1), check_out_on: Date.new(2026, 1, 3))
      newer = create(:reservation, guest: guest, check_in_on: Date.new(2026, 5, 1), check_out_on: Date.new(2026, 5, 3))

      expect(guest.reservations).to eq([ newer, older ])
    end
  end
end
