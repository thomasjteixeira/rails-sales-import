class ImportHistoryController < ApplicationController
  before_action :set_import, only: [ :destroy ]

  def index
    @imports = SalesImport.order(created_at: :desc)
                          .page(params[:page])
                          .per(20)

    @total_imports = SalesImport.count
    @successful_imports = SalesImport.where(status: :completed).count
    @failed_imports = SalesImport.where(status: :failed).count
    @pending_imports = SalesImport.where(status: :pending).count
    @total_gross_income = SalesImport.where(status: :completed).sum(:total_sales_cents)
  end

  def destroy
    @import.destroy

    redirect_to import_history_path, notice: "Import '#{@import.filename}' was successfully deleted."
  rescue StandardError => e
    redirect_to import_history_path, alert: "Failed to delete import: #{e.message}"
  end

  private

  def set_import
    @import = SalesImport.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to import_history_path, alert: "Import not found."
  end
end
