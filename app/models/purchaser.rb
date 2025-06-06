class Purchaser < ApplicationRecord
  has_many :sales, dependent: :destroy

  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
end
