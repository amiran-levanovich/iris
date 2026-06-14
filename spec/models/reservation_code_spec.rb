require "rails_helper"

RSpec.describe ReservationCode do
  describe ".generate" do
    it "returns a 6-character code by default" do
      expect(ReservationCode.generate.length).to eq(6)
    end

    it "honours a custom length" do
      expect(ReservationCode.generate(10).length).to eq(10)
    end

    it "uses only the ambiguity-safe uppercase alphabet" do
      100.times do
        expect(ReservationCode.generate).to match(/\A[ABCDEFGHJKMNPQRSTUVWXYZ23456789]+\z/)
      end
    end

    it "excludes look-alike characters (I, L, O, 0, 1)" do
      sample = Array.new(200) { ReservationCode.generate }.join
      expect(sample).not_to match(/[ILO01]/)
    end

    it "varies between calls" do
      expect(Array.new(20) { ReservationCode.generate }.uniq.length).to be > 1
    end
  end
end
