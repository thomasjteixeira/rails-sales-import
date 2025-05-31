class CreateSales < ActiveRecord::Migration[8.0]
  def change
    create_table :sales do |t|
      t.references :purchaser, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.references :merchant, null: false, foreign_key: true
      t.references :sales_import, null: false, foreign_key: true
      t.integer :item_price_cents
      t.integer :purchase_count
      t.integer :gross_revenue_cents

      t.timestamps
    end
  end
end
