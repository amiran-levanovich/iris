# frozen_string_literal: true

module Reservations
  # Books a room for a guest over a stay period. Owns the transaction that
  # checks availability and creates the reservation so the overlap check and
  # the insert cannot race apart. Captures the room's current nightly rate as a
  # snapshot, keeping historical reservations stable when rates change.
  class BookRoom
    def self.call(...)
      new(...).call
    end

    def initialize(room:, guest:, stay_period:)
      @room = room
      @guest = guest
      @stay_period = stay_period
    end

    def call
      # Single writer (SQLite) makes this check-then-create race-safe locally;
      # availability lives in one place — the Room.available_between scope.
      raise PastDateError if @stay_period.starts_in_past?

      Reservation.transaction do
        raise RoomUnavailableError unless Room.available_between(@stay_period).exists?(@room.id)

        Reservation.create!(
          room: @room,
          guest: @guest,
          check_in_on: @stay_period.check_in,
          check_out_on: @stay_period.check_out,
          nightly_rate_cents: @room.nightly_rate_cents
        )
      end
    end
  end
end
