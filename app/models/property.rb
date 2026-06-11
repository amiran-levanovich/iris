class Property < ApplicationRecord
  has_many :rooms, -> { order(:number) }, dependent: :restrict_with_error

  validates :name, presence: true
  validates :stars, numericality: { only_integer: true, in: 1..5 }, allow_nil: true
end
