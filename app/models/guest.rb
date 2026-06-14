class Guest < ApplicationRecord
  has_many :reservations, -> { order(check_in_on: :desc) }, dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, uniqueness: { allow_blank: true }

  # Name search for the booking guest picker. SQLite LIKE is case-insensitive
  # for ASCII; the term is bound, never interpolated into SQL.
  scope :search, ->(query) { where("name LIKE ?", "%#{query}%") }
end
