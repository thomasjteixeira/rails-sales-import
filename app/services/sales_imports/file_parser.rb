
module SalesImports
  class FileParser
    require "dry/monads"
    include Dry::Monads[:result]

    DEFAULT_OPTIONS = {
      col_sep: "\t",
      quote_char: '"',
      remove_empty_values: true,
      strip_whitespace: true,
      convert_values_to_numeric: false
    }.freeze

    def call(file_blob)
      begin
        parsed_data = parse_file(file_blob)
        Success(parsed_data)
      rescue StandardError => e
        Rails.logger.error("File parsing failed: #{e.message}")
        Failure("Failed to parse file: #{e.message}")
      end
    end

    private

    def parse_file(file_blob)
      rows = []
      invalid_rows = []

      file_blob.open do |tempfile|
        SmarterCSV.process(tempfile.path, DEFAULT_OPTIONS) do |chunk|
          chunk.each_with_index do |row, index|
            next if row.values.all?(&:blank?)

            parsed_row = parse_row(row)

            if valid_row?(parsed_row)
              rows << parsed_row
            else
              invalid_rows << {
                row_number: index + 2, # +2 because index starts at 0 and we have a header
                errors: validate_row_errors(parsed_row)
              }
            end
          end
        end
      end

      if invalid_rows.any?
        error_details = invalid_rows.map do |invalid|
          "Row #{invalid[:row_number]}: #{invalid[:errors].join(', ')}"
        end.join("; ")

        raise StandardError, "Invalid data found - #{error_details}"
      end

      rows
    end

    def parse_row(row)
      {
        purchaser_name: sanitize_string(row[:purchaser_name]),
        item_description: sanitize_string(row[:item_description]),
        item_price: parse_price(row[:item_price]),
        purchase_count: row[:purchase_count].to_i,
        merchant_address: sanitize_string(row[:merchant_address]),
        merchant_name: sanitize_string(row[:merchant_name])
      }
    end

    def valid_row?(row_data)
      validate_row_errors(row_data).empty?
    end

    def validate_row_errors(row_data)
      errors = []

      errors << "purchaser name is required" if row_data[:purchaser_name].blank?
      errors << "item description is required" if row_data[:item_description].blank?
      errors << "item price must be greater than 0" if row_data[:item_price] <= 0
      errors << "purchase count must be greater than 0" if row_data[:purchase_count] <= 0
      errors << "merchant address is required" if row_data[:merchant_address].blank?
      errors << "merchant name is required" if row_data[:merchant_name].blank?

      errors
    end

    def sanitize_string(value)
      return nil if value.nil?
      cleaned = value.to_s.strip
      cleaned.empty? ? nil : cleaned
    end

    def parse_price(price_value)
      return 0 if price_value.blank?

      if price_value.is_a?(Numeric)
        (price_value * 100).to_i
      else
        (price_value.to_f * 100).to_i
      end
    end
  end
end
