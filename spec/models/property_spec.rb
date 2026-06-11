require "rails_helper"

RSpec.describe Property, type: :model do
  describe "validations" do
    it "is valid with the factory defaults" do
      expect(build(:property)).to be_valid
    end

    it "requires a name" do
      property = build(:property, name: nil)

      expect(property).not_to be_valid
      expect(property.errors[:name]).to be_present
    end

    context "with stars" do
      it "accepts ratings from 1 to 5" do
        expect(build(:property, stars: 1)).to be_valid
        expect(build(:property, stars: 5)).to be_valid
      end

      it "rejects ratings outside 1..5" do
        expect(build(:property, stars: 0)).not_to be_valid
        expect(build(:property, stars: 6)).not_to be_valid
      end

      it "allows no rating" do
        expect(build(:property, stars: nil)).to be_valid
      end
    end
  end

  describe "#rooms" do
    it "returns rooms ordered by number" do
      property = create(:property)
      create(:room, property: property, number: "201")
      create(:room, property: property, number: "101")

      expect(property.rooms.map(&:number)).to eq([ "101", "201" ])
    end

    it "prevents destroying a property that has rooms" do
      property = create(:property)
      create(:room, property: property)

      expect(property.destroy).to be(false)
      expect(property.errors[:base]).to be_present
    end
  end
end
