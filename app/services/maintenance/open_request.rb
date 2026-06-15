# frozen_string_literal: true

module Maintenance
  # Opens a maintenance request against a room and takes the room out of service
  # in the same transaction. The cross-aggregate room-status write lives here,
  # never in an AASM callback (see architecture.md / ddd-principles.md §5).
  #
  # Receives an already-built (unsaved) request so the controller owns params
  # extraction and enum-boundary handling (mirrors RoomsController).
  class OpenRequest
    def self.call(...)
      new(...).call
    end

    def initialize(room:, request:)
      @room = room
      @request = request
    end

    def call
      MaintenanceRequest.transaction do
        @request.save!
        @room.change_status!("out_of_service")
      end

      @request
    end
  end
end
