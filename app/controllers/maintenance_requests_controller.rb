class MaintenanceRequestsController < ApplicationController
  before_action :set_room, only: %i[ index new create ]
  before_action :set_maintenance_request, only: %i[ edit update start resolve cancel ]

  # An illegal lifecycle move (e.g. resolving an already-resolved request) is a
  # user action against stale state, not a server fault (mirrors ReservationsController).
  rescue_from AASM::InvalidTransition do
    redirect_to room_maintenance_requests_path(@maintenance_request.room),
                alert: t("maintenance_requests.invalid_transition")
  end

  def index
    @maintenance_requests = @room.maintenance_requests
                                 .includes(:assignee)
                                 .order(created_at: :desc)
  end

  def new
    @maintenance_request = @room.maintenance_requests.build
  end

  def create
    @maintenance_request = @room.maintenance_requests.build

    unless assign_attributes_safely
      return render :new, status: :unprocessable_entity
    end

    Maintenance::OpenRequest.call(room: @room, request: @maintenance_request)
    redirect_to room_maintenance_requests_path(@room), notice: t(".notice")
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    if assign_attributes_safely && @maintenance_request.save
      redirect_to room_maintenance_requests_path(@maintenance_request.room), notice: t(".notice")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def start
    @maintenance_request.start!
    redirect_to room_maintenance_requests_path(@maintenance_request.room), notice: t(".notice")
  end

  def resolve
    Maintenance::CloseRequest.call(request: @maintenance_request, outcome: :resolve)
    redirect_to room_maintenance_requests_path(@maintenance_request.room), notice: t(".notice")
  end

  def cancel
    Maintenance::CloseRequest.call(request: @maintenance_request, outcome: :cancel)
    redirect_to room_maintenance_requests_path(@maintenance_request.room), notice: t(".notice")
  end

  private

  # String enums raise ArgumentError on unknown values instead of failing
  # validation, so the HTTP boundary maps that to a form error, not a 500
  # (mirrors RoomsController#assign_room_attributes).
  def assign_attributes_safely
    @maintenance_request.assign_attributes(maintenance_request_params)
    true
  rescue ArgumentError
    @maintenance_request.errors.add(:category, :invalid)
    false
  end

  def set_room
    @room = Room.find(params.expect(:room_id))
  end

  def set_maintenance_request
    @maintenance_request = MaintenanceRequest.find(params.expect(:id))
  end

  def maintenance_request_params
    params.expect(maintenance_request: [ :title, :description, :category, :priority, :assignee_id ])
  end
end
