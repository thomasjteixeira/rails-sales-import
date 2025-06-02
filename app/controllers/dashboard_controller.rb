class DashboardController < ApplicationController
  def index
    @recent_imports = SalesImport.includes(:sales)
                                .order(created_at: :desc)
                                .limit(5)

    @last_gross_income = calculate_last_gross_income
    @total_gross_income = calculate_total_gross_income
  end

  def upload
    if params[:import_file].present?
      sales_import = SalesImport.create!(status: :pending)

      sales_import.import_file.attach(params[:import_file])

      if sales_import.import_file.attached?
        sales_import.update!(filename: sales_import.import_file.filename.to_s)

        service = SalesImport::Create.new(sales_import: sales_import)

        if service.call
          redirect_to root_path, notice: "File uploaded and processed successfully!"
        else
          sales_import.update!(status: :failed)
          redirect_to root_path, alert: "Failed to process file: #{service.errors.full_messages.join(', ')}"
        end
      else
        sales_import.update!(status: :failed)
        redirect_to root_path, alert: "Failed to attach file. Please try again."
      end
    else
      redirect_to root_path, alert: "Please select a file to upload."
    end
  end

  private

  def calculate_last_gross_income
    last_import = SalesImport.where(status: :completed).order(created_at: :desc).first

    return 0 unless last_import

    last_import.total_sales_cents || 0
  end

  def calculate_total_gross_income
    SalesImport.where(status: :completed)
               .sum(:total_sales_cents) || 0
  end
end
