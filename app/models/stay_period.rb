# frozen_string_literal: true

# Value object for a stay's date span. Half-open [check_in, check_out): a stay
# ending on the day another begins does not overlap, so back-to-back bookings
# of the same room are allowed.
StayPeriod = Data.define(:check_in, :check_out) do
  def valid?
    check_in.present? && check_out.present? && check_out > check_in
  end

  def nights
    (check_out - check_in).to_i
  end

  def overlaps?(other)
    check_in < other.check_out && other.check_in < check_out
  end
end
