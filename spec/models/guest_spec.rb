require "rails_helper"

RSpec.describe Guest, type: :model do
  describe "validations" do
    it "is valid with the factory defaults" do
      expect(build(:guest)).to be_valid
    end

    it "requires first and last name" do
      guest = build(:guest, first_name: nil, last_name: nil)

      expect(guest).not_to be_valid
      expect(guest.errors[:first_name]).to be_present
      expect(guest.errors[:last_name]).to be_present
    end

    it "requires an email" do
      guest = build(:guest, email: nil)

      expect(guest).not_to be_valid
      expect(guest.errors[:email]).to be_present
    end

    it "requires the full address" do
      guest = build(:guest, street: nil, city: nil, postal_code: nil, country: nil)

      expect(guest).not_to be_valid
      expect(guest.errors).to include(:street, :city, :postal_code, :country)
    end

    it "rejects a duplicate email" do
      create(:guest, email: "taken@example.com")
      duplicate = build(:guest, email: "taken@example.com")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end
  end

  describe "#name" do
    it "combines first and last name" do
      expect(build(:guest, first_name: "Ada", last_name: "Lovelace").name).to eq("Ada Lovelace")
    end
  end

  describe ".search" do
    it "matches either name part case-insensitively" do
      ada = create(:guest, first_name: "Ada", last_name: "Lovelace")
      create(:guest, first_name: "Grace", last_name: "Hopper")

      expect(Guest.search("lovel")).to contain_exactly(ada)
      expect(Guest.search("ADA")).to contain_exactly(ada)
      expect(Guest.search("ada lov")).to contain_exactly(ada)
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
