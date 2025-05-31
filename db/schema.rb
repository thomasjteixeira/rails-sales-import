# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_05_31_214023) do
  create_table "items", force: :cascade do |t|
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "merchants", force: :cascade do |t|
    t.string "name"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "purchasers", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sales", force: :cascade do |t|
    t.integer "purchaser_id", null: false
    t.integer "item_id", null: false
    t.integer "merchant_id", null: false
    t.integer "sales_import_id", null: false
    t.integer "item_price_cents"
    t.integer "purchase_count"
    t.integer "gross_revenue_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_sales_on_item_id"
    t.index ["merchant_id"], name: "index_sales_on_merchant_id"
    t.index ["purchaser_id"], name: "index_sales_on_purchaser_id"
    t.index ["sales_import_id"], name: "index_sales_on_sales_import_id"
  end

  create_table "sales_imports", force: :cascade do |t|
    t.string "filename"
    t.integer "status", default: 0, null: false
    t.integer "total_sales_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "sales", "items"
  add_foreign_key "sales", "merchants"
  add_foreign_key "sales", "purchasers"
  add_foreign_key "sales", "sales_imports"
end
