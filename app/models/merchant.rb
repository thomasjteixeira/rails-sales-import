class Merchant < ApplicationRecord
  has_many :sales, dependent: :destroy

  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :address, presence: true, length: { minimum: 3, maximum: 255 }
end
