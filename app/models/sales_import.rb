class SalesImport < ApplicationRecord
  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }, default: :pending, prefix: true

  has_many :sales, dependent: :destroy
  has_one_attached :import_file

  validates :total_sales_cents,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 },
            on: :update

  scope :successful, -> { where(status: :completed) }
  scope :recent, -> { order(created_at: :desc) }

  def revenue_in_reais
    return 0.0 if total_sales_cents.nil?
    total_sales_cents / 100.0
  end

  def sales_count
    sales.count
  end
end
