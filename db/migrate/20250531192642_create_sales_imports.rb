class CreateSalesImports < ActiveRecord::Migration[8.0]
  def change
    create_table :sales_imports do |t|
      t.string :filename, null: true
      t.integer :status, null: false, default: 0
      t.integer :total_sales_cents, null: false, default: 0

      t.timestamps
    end
  end
end
