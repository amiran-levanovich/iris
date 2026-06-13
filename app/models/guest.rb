class Guest < ApplicationRecord
  has_many :reservations, -> { order(check_in_on: :desc) }, dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, uniqueness: { allow_blank: true }
end
