class RoomsController < ApplicationController
  before_action :set_property, only: %i[ new create ]
  before_action :set_room, only: %i[ edit update status ]

  def new
    @room = @property.rooms.build
  end

  def create
    @room = @property.rooms.build(room_params)

    if @room.save
      redirect_to @property, notice: t(".notice")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @room.update(room_params)
      redirect_to @room.property, notice: t(".notice")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def status
    @room.change_status!(params.expect(:status))
    redirect_to @room.property, notice: t(".notice")
  rescue ArgumentError
    redirect_to @room.property, alert: t(".alert")
  end

  private

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
