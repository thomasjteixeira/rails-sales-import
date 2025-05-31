FactoryBot.define do
  factory :sale do
    association :purchaser
    association :item
    association :merchant
    association :sales_import
    item_price_cents { Faker::Commerce.price(range: 1..10000).to_i }
    purchase_count { Faker::Number.between(from: 1, to: 50) }
    gross_revenue_cents { 0 }
  end
end
