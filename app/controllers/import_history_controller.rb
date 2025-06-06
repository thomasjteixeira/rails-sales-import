class ImportHistoryController < ApplicationController
  include Dry::Monads[:result]

  before_action :set_import, only: [ :destroy ]

  def index
    @imports = SalesImport.includes(:sales)
                          .order(created_at: :desc)
    @statistics = SalesImport.calculate_statistics
  end

  def destroy
    result = destroy_import

    case result
    in Success(message)
      redirect_to import_history_index_path, notice: message
    in Failure(error_message)
      redirect_to import_history_index_path, alert: error_message
    end
  end

  private

  def destroy_import
    begin
      @import.destroy!
      Success("Import '#{@import.filename}' was successfully deleted.")
    rescue StandardError => e
      Rails.logger.error("Failed to delete import #{@import.id}: #{e.message}")
      Failure("Failed to delete import: #{e.message}")
    end
  end

  def set_import
    @import = SalesImport.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to import_history_index_path, alert: "Import not found."
  end
end
