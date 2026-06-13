require "rails_helper"

RSpec.describe StayPeriod do
  def period(check_in, check_out)
    described_class.new(check_in: Date.new(2026, 6, check_in), check_out: Date.new(2026, 6, check_out))
  end

  describe "#valid?" do
    it "is valid when check-out follows check-in" do
      expect(period(1, 3)).to be_valid
    end

    it "is invalid when check-out equals check-in" do
      expect(period(1, 1)).not_to be_valid
    end

    it "is invalid when check-out precedes check-in" do
      expect(period(3, 1)).not_to be_valid
    end

    it "is invalid when a date is missing" do
      expect(described_class.new(check_in: nil, check_out: Date.current)).not_to be_valid
    end
  end

  describe "#nights" do
    it "counts the nights in the span" do
      expect(period(1, 4).nights).to eq(3)
    end
  end

  describe "#overlaps?" do
    it "detects an overlapping span" do
      expect(period(1, 5).overlaps?(period(3, 7))).to be(true)
    end

    it "treats the range as half-open so back-to-back stays do not overlap" do
      expect(period(1, 4).overlaps?(period(4, 6))).to be(false)
    end

    it "is false for fully separate spans" do
      expect(period(1, 3).overlaps?(period(10, 12))).to be(false)
    end
  end
end
