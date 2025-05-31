FactoryBot.define do
  factory :item do
    description { Faker::Commerce.product_name }
  end
end
