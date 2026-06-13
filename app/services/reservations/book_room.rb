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
      Reservation.transaction do
        raise RoomUnavailableError if @room.out_of_service?
        raise RoomUnavailableError if @room.reservations.overlapping(@stay_period).exists?

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
