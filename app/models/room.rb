class Room < ApplicationRecord
  belongs_to :property

  enum :room_type, {
    single: "single",
    double: "double",
    twin: "twin",
    suite: "suite",
    family: "family",
    deluxe: "deluxe",
    penthouse: "penthouse"
  }

  enum :status, {
    operational: "operational",
    cleaning: "cleaning",
    out_of_service: "out_of_service"
  }

  validates :number, presence: true, uniqueness: { scope: :property_id }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :nightly_rate_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :floor, numericality: { only_integer: true }, allow_nil: true

  def change_status!(new_status)
    self.status = new_status
    save!
  end
end
