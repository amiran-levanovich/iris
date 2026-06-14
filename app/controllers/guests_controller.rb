class GuestsController < ApplicationController
  before_action :set_guest, only: %i[ show edit update ]

  def index
    @guests = params[:q].present? ? Guest.search(params[:q]).order(:name) : Guest.order(:name)

    # The booking guest picker searches into a Turbo Frame; reply with just the
    # results list, not the whole page.
    if turbo_frame_request_id == "guest_results"
      render partial: "guests/picker_results",
             locals: { guests: @guests, query: params[:q].to_s }, layout: false
    end
  end

  def show
    @reservations = @guest.reservations.includes(room: :property)
  end

  def new
    @guest = Guest.new
  end

  def create
    @guest = Guest.new(guest_params)
    saved = @guest.save

    respond_to do |format|
      # Inline create from the booking picker: select the new guest in place.
      format.turbo_stream { render :create, status: saved ? :ok : :unprocessable_entity }
      format.html do
        if saved
          redirect_to @guest, notice: t(".notice")
        else
          render :new, status: :unprocessable_entity
        end
      end
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
    params.expect(guest: [ :name, :email, :phone ])
  end
end
