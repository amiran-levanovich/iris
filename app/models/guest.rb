class Guest < ApplicationRecord
  has_many :reservations, -> { order(check_in_on: :desc) }, dependent: :restrict_with_error

  validates :first_name, :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :street, :city, :postal_code, :country, presence: true
  # country stores an ISO-3166 alpha-2 code chosen from the country picker.
  validates :country, inclusion: { in: ISO3166::Country.codes }, allow_blank: true

  # Name search for the booking guest picker. SQLite LIKE is case-insensitive
  # for ASCII; the term is bound, never interpolated into SQL. Matches either
  # name part or the combined full name so "ada", "lovelace" and "ada lov" hit.
  scope :search, ->(query) {
    where("first_name LIKE :q OR last_name LIKE :q OR (first_name || ' ' || last_name) LIKE :q",
          q: "%#{query}%")
  }

  def name
    "#{first_name} #{last_name}".strip
  end
end
