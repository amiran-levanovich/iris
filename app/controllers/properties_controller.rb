class PropertiesController < ApplicationController
  before_action :set_property, only: %i[ edit update ]

  def index
    @properties = Property.order(:name)
  end

  def show
    @property = Property.includes(:rooms).find(params.expect(:id))
    @current_reservations = Reservation.checked_in
                                       .where(room: @property.rooms)
                                       .includes(:guest)
                                       .index_by(&:room_id)
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
