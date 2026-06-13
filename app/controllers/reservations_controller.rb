class ReservationsController < ApplicationController
  before_action :set_property, only: %i[ index new create ]
  before_action :set_reservation, only: %i[ check_in check_out cancel ]

  # An illegal lifecycle move (e.g. checking out a reservation that was never
  # checked in) is a user action against stale state, not a server fault.
  rescue_from AASM::InvalidTransition do |error|
    redirect_to property_reservations_path(error.object.room.property),
                alert: t("reservations.invalid_transition")
  end

  def index
    today = Date.current
    @arrivals = @property.reservations.arriving_on(today).includes(:guest, :room)
    @departures = @property.reservations.departing_on(today).includes(:guest, :room)
    @in_house = @property.reservations.checked_in.includes(:guest, :room)
  end

  def new
    @stay_period = stay_period_from(params)
    @rooms = @property.rooms.available_between(@stay_period)
    @guests = Guest.order(:name)
  end

  def create
    @stay_period = stay_period_from(reservation_params)
    room = @property.rooms.find(reservation_params[:room_id])
    guest = Guest.find(reservation_params[:guest_id])

    Reservations::BookRoom.call(room:, guest:, stay_period: @stay_period)
    redirect_to property_reservations_path(@property), notice: t(".notice")
  rescue Reservations::RoomUnavailableError
    setup_booking_form
    flash.now[:alert] = t(".unavailable")
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => error
    @reservation = error.record
    setup_booking_form
    render :new, status: :unprocessable_entity
  end

  def check_in
    @reservation.check_in!
    redirect_to property_reservations_path(property_for(@reservation)), notice: t(".notice")
  end

  def check_out
    Reservations::CheckOut.call(reservation: @reservation)
    redirect_to property_reservations_path(property_for(@reservation)), notice: t(".notice")
  end

  def cancel
    @reservation.cancel!
    redirect_to property_reservations_path(property_for(@reservation)), notice: t(".notice")
  end

  private

  def set_property
    @property = Property.find(params.expect(:property_id))
  end

  def set_reservation
    @reservation = Reservation.find(params.expect(:id))
  end

  def property_for(reservation)
    reservation.room.property
  end

  def setup_booking_form
    @rooms = @property.rooms.available_between(@stay_period)
    @guests = Guest.order(:name)
  end

  # Builds the requested stay from a params-like hash, defaulting to a one-night
  # stay starting today when dates are missing or unparseable.
  def stay_period_from(source)
    StayPeriod.new(
      check_in: parse_date(source[:check_in_on], Date.current),
      check_out: parse_date(source[:check_out_on], Date.current.next_day)
    )
  end

  def parse_date(value, fallback)
    Date.iso8601(value.to_s)
  rescue ArgumentError
    fallback
  end

  def reservation_params
    params.expect(reservation: [ :guest_id, :room_id, :check_in_on, :check_out_on ])
  end
end
