class RoomsController < ApplicationController
  before_action :set_property, only: %i[ index new create ]
  before_action :set_room, only: %i[ edit update status ]

  # Housekeeping tab: the room dashboard with occupancy.
  def index
    @current_reservations = Reservation.checked_in
                                       .where(room: @property.rooms)
                                       .includes(:guest)
                                       .index_by(&:room_id)
    @maintenance_counts = MaintenanceRequest.active
                                            .where(room: @property.rooms)
                                            .group(:room_id)
                                            .count
  end

  def new
    @room = @property.rooms.build
  end

  def create
    @room = @property.rooms.build

    if assign_room_attributes(@room) && @room.save
      redirect_to property_rooms_path(@property), notice: t(".notice")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if assign_room_attributes(@room) && @room.save
      redirect_to property_rooms_path(@room.property), notice: t(".notice")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def status
    @room.change_status!(params.expect(:status))
    redirect_to property_rooms_path(@room.property), notice: t(".notice")
  rescue ArgumentError
    redirect_to property_rooms_path(@room.property), alert: t(".alert")
  end

  private

  # String enums raise ArgumentError on unknown values instead of failing
  # validation, so the HTTP boundary maps that to a form error, not a 500.
  def assign_room_attributes(room)
    room.assign_attributes(room_params)
    true
  rescue ArgumentError
    room.errors.add(:room_type, :invalid)
    false
  end

  def set_property
    @property = Property.find(params.expect(:property_id))
  end

  def set_room
    @room = Room.find(params.expect(:id))
  end

  def room_params
    params.expect(room: [ :number, :room_type, :capacity, :nightly_rate_cents, :floor, :description ])
  end
end
