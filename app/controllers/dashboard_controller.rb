class DashboardController < ApplicationController
  def index
    @recent_imports = SalesImport.includes(:sales)
                                .order(created_at: :desc)
                                .limit(5)

    @last_gross_income = calculate_last_gross_income
    @total_gross_income = calculate_total_gross_income
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
