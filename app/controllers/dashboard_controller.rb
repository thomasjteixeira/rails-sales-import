class DashboardController < ApplicationController
  include Dry::Monads[:result]

  def index
    @recent_imports = SalesImport.recent_imports
    @last_gross_income = SalesImport.last_gross_income
    @total_gross_income = SalesImport.total_gross_income
  end

  def upload
    if params[:import_file].blank?
      redirect_to root_path, alert: "Please select a file to upload."
      return
    end

    sales_import = create_sales_import
    return unless sales_import

    enqueue_processing_job(sales_import)
  end

  private

  def create_sales_import
    sales_import = SalesImport.create!(status: :pending)
    sales_import.import_file.attach(params[:import_file])

    if sales_import.import_file.attached?
      sales_import.update!(filename: sales_import.import_file.filename.to_s)
      sales_import
    else
      sales_import.update!(status: :failed)
      redirect_to root_path, alert: "Failed to attach file. Please try again."
      nil
    end
  end

  def enqueue_processing_job(sales_import)
    SalesImportProcessingJob.perform_later(sales_import.id)
    redirect_to root_path, notice: "File uploaded successfully! Processing in background..."
  rescue StandardError => e
    Rails.logger.error "Failed to enqueue processing job for sales import #{sales_import.id}: #{e.message}"
    sales_import.update!(status: :failed)
    redirect_to root_path, alert: "Failed to start processing. Please try again."
  end
end
