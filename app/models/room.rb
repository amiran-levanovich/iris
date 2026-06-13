class Room < ApplicationRecord
  belongs_to :property
  has_many :reservations, dependent: :restrict_with_error

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

  # Rooms sellable for a stay: never out_of_service (cleaning is transient and
  # still bookable) and free of any reservation overlapping the period.
  scope :available_between, ->(period) {
    where.not(status: :out_of_service)
      .where.not(id: Reservation.overlapping(period).select(:room_id))
  }

  def change_status!(new_status)
    self.status = new_status
    save!
  end

  def current_reservation
    reservations.checked_in.first
  end
end
