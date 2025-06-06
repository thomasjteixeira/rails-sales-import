module SalesImports
  class SalesCreator
    include Dry::Monads[:result]

    def initialize(sales_import)
      @sales_import = sales_import
    end

    def call(sales_data_list)
      begin
        result = process_sales_data(sales_data_list)
        Success(result)
      rescue StandardError => e
        Rails.logger.error("Sales creation failed: #{e.message}")
        Failure("Failed to create sales: #{e.message}")
      end
    end

    private

    attr_reader :sales_import

    def process_sales_data(sales_data_list)
      total_revenue = 0
      processed_count = 0
      failed_count = 0
      validation_errors = []

      sales_data_list.each_with_index do |sale_data, index|
        unless valid_sale_data?(sale_data)
          failed_count += 1
          errors = validate_sale_data_errors(sale_data)
          validation_errors << "Row #{index + 2}: #{errors.join(', ')}"
          next
        end

        sale = create_sale(sale_data)

        if sale&.persisted?
          total_revenue += sale.gross_revenue_cents
          processed_count += 1
        else
          failed_count += 1
          validation_errors << "Row #{index + 2}: Failed to create sale record"
        end
      end

      if processed_count == 0
        raise StandardError, "All sales failed validation or creation: #{validation_errors.join('; ')}"
      end

      if failed_count > 0
        Rails.logger.warn("Some sales failed: #{validation_errors.join('; ')}")
        raise StandardError, "#{failed_count} sales failed validation or creation: #{validation_errors.join('; ')}"
      end

      {
        total_revenue: total_revenue,
        processed_count: processed_count
      }
    end

    def valid_sale_data?(sale_data)
      validate_sale_data_errors(sale_data).empty?
    end

    def validate_sale_data_errors(sale_data)
      errors = []

      errors << "purchaser name is required" if sale_data[:purchaser_name].blank?
      errors << "item description is required" if sale_data[:item_description].blank?
      errors << "item price must be greater than 0" if sale_data[:item_price] <= 0
      errors << "purchase count must be greater than 0" if sale_data[:purchase_count] <= 0
      errors << "merchant address is required" if sale_data[:merchant_address].blank?
      errors << "merchant name is required" if sale_data[:merchant_name].blank?

      errors
    end

    def create_sale(sale_data)
      purchaser = find_or_create_purchaser(sale_data[:purchaser_name])
      item = find_or_create_item(sale_data[:item_description])
      merchant = find_or_create_merchant(
        sale_data[:merchant_name],
        sale_data[:merchant_address]
      )

      return nil unless purchaser && item && merchant

      Sale.create!(
        purchaser: purchaser,
        item: item,
        merchant: merchant,
        sales_import: sales_import,
        purchase_count: sale_data[:purchase_count],
        item_price_cents: sale_data[:item_price]
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("Failed to create sale: #{e.message}")
      nil
    end

    def find_or_create_purchaser(name)
      return nil if name.blank?
      Purchaser.find_or_create_by(name: name)
    rescue ActiveRecord::RecordInvalid
      nil
    end

    def find_or_create_item(description)
      return nil if description.blank?
      Item.find_or_create_by(description: description)
    rescue ActiveRecord::RecordInvalid
      nil
    end

    def find_or_create_merchant(name, address)
      return nil if name.blank? || address.blank?
      Merchant.find_or_create_by(name: name, address: address)
    rescue ActiveRecord::RecordInvalid
      nil
    end
  end
end
