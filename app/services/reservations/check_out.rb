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
        # Don't undo an active maintenance block: a room with open maintenance
        # stays out_of_service rather than becoming cleaning (and bookable).
        room = @reservation.room
        room.change_status!("cleaning") unless MaintenanceRequest.active_for(room).any?
      end

      @reservation
    end
  end
end
