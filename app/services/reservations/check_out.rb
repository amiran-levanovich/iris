# frozen_string_literal: true

module Reservations
  # Checks a guest out. Owns the transaction for the cross-aggregate effect:
  # the reservation transitions to checked_out and its room flips to cleaning.
  # This orchestration lives here, never in an AASM callback — callbacks must
  # not touch another aggregate (see architecture.md).
  class CheckOut
    def self.call(...)
      new(...).call
    end

    def initialize(reservation:)
      @reservation = reservation
    end

    def call
      Reservation.transaction do
        @reservation.check_out!
        @reservation.room.change_status!("cleaning")
      end

      @reservation
    end
  end
end
