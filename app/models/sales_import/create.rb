# frozen_string_literal: true

require "smarter_csv"

class SalesImport
  class Create
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_accessor :sales_import

    validates :sales_import, presence: true
    validate :file_attached

    def call
      return false unless valid?

      ActiveRecord::Base.transaction do
        sales_import.update!(status: :processing)

        total_revenue = 0
        processed_rows = 0

        options = {
          col_sep: "\t",
          quote_char: '"',
          remove_empty_values: true,
          strip_whitespace: true,
          convert_values_to_numeric: false
        }

        sales_import.import_file.blob.open do |tempfile|
          SmarterCSV.process(tempfile.path, options) do |chunk|
            chunk.each do |row|
              next if row.values.all?(&:blank?)

              sale_data = parse_row(row)
              sale = create_sale(sale_data)

              total_revenue += sale.gross_revenue_cents if sale.persisted?
              processed_rows += 1
            end
          end
        end

        sales_import.update!(
          total_sales_cents: total_revenue,
          status: :completed,
          filename: sales_import.import_file.filename.to_s
        )

        true
      end

    rescue StandardError => e
      Rails.logger.error("SalesImport failed: #{e.message}")
      sales_import.update!(status: :failed)
      false
    end

    private

    def file_attached
      return if sales_import&.import_file&.attached?

      errors.add(:sales_import, "must have a file attached")
    end

    def parse_row(row)
      {
        purchaser_name: row[:purchaser_name]&.to_s&.strip,
        item_description: row[:item_description]&.to_s&.strip,
        item_price: parse_price(row[:item_price]),
        purchase_count: row[:purchase_count].to_i,
        merchant_address: row[:merchant_address]&.to_s&.strip,
        merchant_name: row[:merchant_name]&.to_s&.strip
      }
    end

    def parse_price(price_value)
      return 0 if price_value.blank?

      if price_value.is_a?(Numeric)
        (price_value * 100).to_i
      else
        (price_value.to_f * 100).to_i
      end
    end

    def create_sale(sale_data)
      purchaser = find_or_create_purchaser(sale_data[:purchaser_name])
      item = find_or_create_item(sale_data[:item_description])
      merchant = find_or_create_merchant(
        sale_data[:merchant_name],
        sale_data[:merchant_address]
      )

      Sale.create!(
        purchaser: purchaser,
        item: item,
        merchant: merchant,
        sales_import: sales_import,
        purchase_count: sale_data[:purchase_count],
        item_price_cents: sale_data[:item_price]
      )
    end

    def find_or_create_purchaser(name)
      return nil if name.blank?

      Purchaser.find_or_create_by(name: name)
    end

    def find_or_create_item(description)
      return nil if description.blank?

      Item.find_or_create_by(description: description)
    end

    def find_or_create_merchant(name, address)
      return nil if name.blank? || address.blank?

      Merchant.find_or_create_by(name: name, address: address)
    end
  end
end
