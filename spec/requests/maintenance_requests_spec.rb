require "rails_helper"

RSpec.describe "MaintenanceRequests", type: :request do
  let(:user) { create(:user) }
  let(:room) { create(:room, status: "operational") }

  before { sign_in(user) }

  describe "GET /rooms/:room_id/maintenance_requests" do
    it "lists the room's requests" do
      create(:maintenance_request, room: room, title: "Leaky pipe")

      get room_maintenance_requests_path(room)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Leaky pipe")
    end
  end

  describe "POST /rooms/:room_id/maintenance_requests" do
    it "opens a request and takes the room out of service" do
      expect {
        post room_maintenance_requests_path(room),
             params: { maintenance_request: { title: "Broken lock", category: "structural", priority: "high" } }
      }.to change(MaintenanceRequest, :count).by(1)

      expect(response).to redirect_to(room_maintenance_requests_path(room))
      expect(room.reload).to be_out_of_service
    end

    it "re-renders with errors and leaves the room untouched when invalid" do
      expect {
        post room_maintenance_requests_path(room),
             params: { maintenance_request: { title: "", category: "plumbing" } }
      }.not_to change(MaintenanceRequest, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(room.reload).to be_operational
    end
  end

  describe "lifecycle transitions" do
    it "starts work on a request" do
      request = create(:maintenance_request, room: room)

      patch start_maintenance_request_path(request)

      expect(request.reload).to be_in_progress
    end

    it "resolves a request and restores the room" do
      room.update!(status: "out_of_service")
      request = create(:maintenance_request, room: room)

      patch resolve_maintenance_request_path(request)

      expect(request.reload).to be_resolved
      expect(room.reload).to be_operational
    end

    it "redirects with an alert on an illegal transition" do
      request = create(:maintenance_request, :resolved, room: room)

      patch resolve_maintenance_request_path(request)

      expect(response).to redirect_to(room_maintenance_requests_path(room))
      expect(flash[:alert]).to be_present
    end
  end

  describe "GET /properties/:property_id/rooms (housekeeping board)" do
    it "shows the active maintenance count for a room" do
      create(:maintenance_request, room: room)

      get property_rooms_path(room.property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("1 open")
    end
  end
end
