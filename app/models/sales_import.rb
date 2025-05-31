class SalesImport < ApplicationRecord
enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }, default: :pending, prefix: true

has_many :sales, dependent: :destroy

validates :filename, presence: true, on: :update
validates :total_sales_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

has_one_attached :import_file
end
