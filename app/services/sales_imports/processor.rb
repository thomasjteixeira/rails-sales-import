module SalesImports
  class Processor
    include Dry::Monads[:result]

    def initialize(sales_import)
      @sales_import = sales_import
    end

    def call
      return Failure("Sales import not found") unless @sales_import
      return Failure("No file attached") unless @sales_import.import_file.attached?

      begin
        process_import
      rescue StandardError => e
        Rails.logger.error("SalesImport failed: #{e.message}")
        update_import_status(:failed)
        Failure("Processing failed: #{e.message}")
      end
    end

    private

    attr_reader :sales_import

    def process_import
      update_import_status(:processing)

      ActiveRecord::Base.transaction do
        result = parse_and_create_sales
        return result if result.failure?

        sales_data = result.value!

        sales_import.update!(
          total_sales_cents: sales_data[:total_revenue],
          status: :completed,
          filename: sales_import.import_file.filename.to_s
        )

        Success(sales_import)
      end
    rescue StandardError => e
      update_import_status(:failed)
      raise e
    end

    def parse_and_create_sales
      parser = SalesImports::FileParser.new
      creator = SalesImports::SalesCreator.new(sales_import)

      parse_result = parser.call(sales_import.import_file.blob)
      if parse_result.failure?
        update_import_status(:failed)
        return parse_result
      end

      parsed_data = parse_result.value!
      if parsed_data.empty?
        update_import_status(:failed)
        return Failure("No valid data found in file")
      end

      creation_result = creator.call(parsed_data)
      if creation_result.failure?
        update_import_status(:failed)
        return creation_result
      end

      creation_result
    end

    def update_import_status(status)
      sales_import.update_column(:status, SalesImport.statuses[status])
    rescue StandardError => e
      Rails.logger.error("Failed to update sales_import status to #{status}: #{e.message}")
    end
  end
end
