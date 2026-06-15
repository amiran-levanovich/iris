class GuestsController < ApplicationController
  before_action :set_guest, only: %i[ show edit update ]

  def index
    scope = params[:q].present? ? Guest.search(params[:q]) : Guest.all
    @guests = scope.order(:last_name, :first_name)

    # The booking guest picker searches into a Turbo Frame; reply with just the
    # results list, not the whole page.
    if turbo_frame_request_id == "guest_results"
      render partial: "guests/picker_results",
             locals: { guests: @guests, query: params[:q].to_s, return_to: params[:return_to] },
             layout: false
    end
  end

  def show
    @reservations = @guest.reservations.includes(room: :property)
  end

  def new
    # The booking picker links here with the typed name split into first/last so
    # the operator only fills the remaining required fields.
    @guest = Guest.new(prefill_params)
  end

  def create
    @guest = Guest.new(guest_params)

    if @guest.save
      # When the picker sent us here mid-booking, return to that booking form
      # with the new guest pre-selected; otherwise show the guest.
      redirect_to booking_return_path || @guest, notice: t(".notice")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @guest.update(guest_params)
      redirect_to @guest, notice: t(".notice")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_guest
    @guest = Guest.find(params.expect(:id))
  end

  def guest_params
    params.expect(guest: [ :first_name, :last_name, :email, :phone, :street, :city, :postal_code, :country ])
  end

  def prefill_params
    return {} unless params[:guest]

    params.expect(guest: [ :first_name, :last_name ])
  end

  # The booking form to return to after creating a guest, with the new guest's
  # id appended so the picker shows it selected. nil unless a safe local
  # return_to was supplied.
  def booking_return_path
    target = safe_internal_path(params[:return_to], nil)
    return nil unless target

    uri = URI.parse(target)
    query = URI.decode_www_form(uri.query || "") << [ "guest_id", @guest.id ]
    uri.query = URI.encode_www_form(query)
    uri.to_s
  rescue URI::InvalidURIError
    nil
  end
end
