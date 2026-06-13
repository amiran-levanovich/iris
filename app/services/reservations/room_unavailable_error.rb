# frozen_string_literal: true

module Reservations
  # Raised when a room cannot take a booking: it is out of service or already
  # held by an overlapping reservation.
  class RoomUnavailableError < StandardError; end
end
