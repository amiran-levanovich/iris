class PropertiesController < ApplicationController
  before_action :set_property, only: %i[ edit update ]

  def index
    @properties = Property.order(:name)
  end

  def show
    @property = Property.includes(:rooms).find(params.expect(:id))

    today = Date.current
    @arrivals = @property.reservations.arriving_on(today).includes(:guest, :room)
    @departures = @property.reservations.departing_on(today).includes(:guest, :room)
    @in_house = @property.reservations.checked_in.includes(:guest, :room)
    # Occupancy on the room board reads from the same in-house load.
    @current_reservations = @in_house.index_by(&:room_id)
  end

  def new
    @property = Property.new
  end

  def create
    @property = Property.new(property_params)

    if @property.save
      redirect_to @property, notice: t(".notice")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @property.update(property_params)
      redirect_to @property, notice: t(".notice")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_property
    @property = Property.find(params.expect(:id))
  end

  def property_params
    params.expect(property: [ :name, :street, :city, :postal_code, :country, :description, :stars ])
  end
end
