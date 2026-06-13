class GuestsController < ApplicationController
  before_action :set_guest, only: %i[ show edit update ]

  def index
    @guests = Guest.order(:name)
  end

  def show
    @reservations = @guest.reservations.includes(room: :property)
  end

  def new
    @guest = Guest.new
  end

  def create
    @guest = Guest.new(guest_params)

    if @guest.save
      redirect_to @guest, notice: t(".notice")
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
    params.expect(guest: [ :name, :email, :phone ])
  end
end
