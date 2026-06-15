# frozen_string_literal: true

module Reservations
  # Raised when a booking's check-in date is in the past. Reservations can only
  # be created for today or a future date; backdated stays are entered as history
  # through other paths, not the booking flow.
  class PastDateError < StandardError; end
end
