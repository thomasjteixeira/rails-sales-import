class Sale < ApplicationRecord
  belongs_to :purchaser
  belongs_to :item
  belongs_to :merchant
  belongs_to :sales_import

  validates :purchase_count, presence: true, numericality: { greater_than: 0 }
  validates :item_price_cents, presence: true, numericality: { greater_than: 0 }

  before_validation :calculate_gross_revenue

  private

  def calculate_gross_revenue
    return unless purchase_count.present? && item_price_cents.present?
      self.gross_revenue_cents = purchase_count * item_price_cents
  end
end
