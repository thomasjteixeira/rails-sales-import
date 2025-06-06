class CreateMerchants < ActiveRecord::Migration[8.0]
  def change
    create_table :merchants do |t|
      t.string :name
      t.text :address

      t.timestamps
    end
  end
end
