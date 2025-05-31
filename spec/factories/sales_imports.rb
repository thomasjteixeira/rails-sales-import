FactoryBot.define do
  factory :sales_import do
    filename { Faker::File.file_name(ext: 'csv') }
    status { 1 } # processing
    total_sales_cents { 1 }
  end
end
