require "rails_helper"

RSpec.describe Maintenance::OpenRequest do
  it "saves the request and takes the room out of service" do
    room = create(:room, status: "operational")
    request = room.maintenance_requests.build(title: "Broken AC", category: "hvac", priority: "high")

    result = described_class.call(room: room, request: request)

    expect(result).to be_persisted
    expect(result).to be_open
    expect(room.reload).to be_out_of_service
  end

  it "rolls back and leaves the room untouched when the request is invalid" do
    room = create(:room, status: "operational")
    request = room.maintenance_requests.build(title: "", category: "hvac")

    expect {
      described_class.call(room: room, request: request)
    }.to raise_error(ActiveRecord::RecordInvalid)

    expect(room.reload).to be_operational
    expect(room.maintenance_requests).to be_empty
  end
end
