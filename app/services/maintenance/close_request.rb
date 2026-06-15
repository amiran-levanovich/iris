# frozen_string_literal: true

module Maintenance
  # Closes a maintenance request (resolved or cancelled) and, if it was the last
  # one holding the room, returns the room to operational. Owns the transaction
  # for the cross-aggregate room-status write — the "any others still active?"
  # check is a query on the MaintenanceRequest aggregate, not a reach from Room.
  class CloseRequest
    OUTCOMES = %i[ resolve cancel ].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(request:, outcome:)
      raise ArgumentError, "unknown outcome: #{outcome.inspect}" unless OUTCOMES.include?(outcome)

      @request = request
      @outcome = outcome
    end

    def call
      MaintenanceRequest.transaction do
        @request.public_send(:"#{@outcome}!")
        room = @request.room
        room.change_status!("operational") if MaintenanceRequest.active_for(room).none?
      end

      @request
    end
  end
end
