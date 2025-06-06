class Item < ApplicationRecord
  has_many :sales, dependent: :destroy

  validates :description, presence: true, length: { minimum: 3, maximum: 50 }
end
