FactoryBot.define do
  factory :merchant do
    name { Faker::Company.name }
    address { Faker::Address.full_address }
  end
end
