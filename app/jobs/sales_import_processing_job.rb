class SalesImportProcessingJob < ApplicationJob
  queue_as :default

  def perform(sales_import_id)
    sales_import = SalesImport.find(sales_import_id)

    result = SalesImports::Processor.new(sales_import).call

    if result.success?
      Rails.logger.info "Sales import #{sales_import_id} processed successfully"
    elsif result.failure?
      failure_message = result.failure
      Rails.logger.error "Sales import #{sales_import_id} failed: #{failure_message}"
      raise StandardError, failure_message
    else
      Rails.logger.error "Sales import #{sales_import_id} received unexpected result: #{result.inspect}"
      raise StandardError, "Unexpected result from processor"
    end

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Sales import #{sales_import_id} not found: #{e.message}"
    raise
  rescue StandardError => e
    Rails.logger.error "Sales import #{sales_import_id} processing failed: #{e.message}"
    raise
  end
end
