require "rails_helper"

RSpec.describe MaintenanceRequest, type: :model do
  describe "validations" do
    it "is valid with the factory defaults" do
      expect(build(:maintenance_request)).to be_valid
    end

    it "requires a title" do
      expect(build(:maintenance_request, title: "")).not_to be_valid
    end

    it "is valid with no assignee" do
      expect(build(:maintenance_request, assignee: nil)).to be_valid
    end

    it "rejects an assignee_id that points to no user" do
      request = build(:maintenance_request, assignee_id: 999_999)

      expect(request).not_to be_valid
      expect(request.errors[:assignee_id]).to be_present
    end
  end

  describe "lifecycle" do
    it "starts open" do
      expect(build(:maintenance_request)).to be_open
    end

    it "walks open -> in_progress -> resolved" do
      request = create(:maintenance_request)

      request.start!
      expect(request).to be_in_progress

      request.resolve!
      expect(request).to be_resolved
    end

    it "can be cancelled from open" do
      request = create(:maintenance_request)

      request.cancel!

      expect(request).to be_cancelled
    end

    it "can be cancelled from in_progress" do
      request = create(:maintenance_request, :in_progress)

      request.cancel!

      expect(request).to be_cancelled
    end

    it "rejects resolving an already-resolved request" do
      request = create(:maintenance_request, :resolved)

      expect { request.resolve! }.to raise_error(AASM::InvalidTransition)
    end
  end

  describe "scopes" do
    it ".active returns open and in_progress requests only" do
      open = create(:maintenance_request)
      in_progress = create(:maintenance_request, :in_progress)
      create(:maintenance_request, :resolved)
      create(:maintenance_request, :cancelled)

      expect(described_class.active).to contain_exactly(open, in_progress)
    end

    it ".active_for scopes active requests to a room" do
      room = create(:room)
      mine = create(:maintenance_request, room: room)
      create(:maintenance_request) # another room
      create(:maintenance_request, :resolved, room: room)

      expect(described_class.active_for(room)).to contain_exactly(mine)
    end
  end
end
