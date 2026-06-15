require "rails_helper"

RSpec.describe Maintenance::CloseRequest do
  it "resolves the request and restores the room when it was the last active one" do
    room = create(:room, status: "out_of_service")
    request = create(:maintenance_request, room: room)

    described_class.call(request: request, outcome: :resolve)

    expect(request.reload).to be_resolved
    expect(room.reload).to be_operational
  end

  it "cancels the request and restores the room" do
    room = create(:room, status: "out_of_service")
    request = create(:maintenance_request, room: room)

    described_class.call(request: request, outcome: :cancel)

    expect(request.reload).to be_cancelled
    expect(room.reload).to be_operational
  end

  it "keeps the room out of service while another active request remains" do
    room = create(:room, status: "out_of_service")
    request = create(:maintenance_request, room: room)
    create(:maintenance_request, room: room) # still open

    described_class.call(request: request, outcome: :resolve)

    expect(request.reload).to be_resolved
    expect(room.reload).to be_out_of_service
  end

  it "rejects an unknown outcome" do
    request = create(:maintenance_request)

    expect {
      described_class.call(request: request, outcome: :archive)
    }.to raise_error(ArgumentError)
  end

  it "raises and leaves state untouched on an illegal transition" do
    room = create(:room, status: "out_of_service")
    request = create(:maintenance_request, :resolved, room: room)

    expect {
      described_class.call(request: request, outcome: :resolve)
    }.to raise_error(AASM::InvalidTransition)

    expect(room.reload).to be_out_of_service
  end
end
