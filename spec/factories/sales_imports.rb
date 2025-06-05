FactoryBot.define do
  factory :sales_import do
    status { :pending }
    total_sales_cents { 0 }
    filename { "valid_sales.tab" }

    trait :pending do
      status { :pending }
    end

    trait :processing do
      status { :processing }
    end

    trait :completed do
      status { :completed }
      total_sales_cents { 1000 }
    end

    trait :failed do
      status { :failed }
    end

    trait :with_file do
      after(:build) do |sales_import|
        file_path = Rails.root.join('spec', 'fixtures', 'files', 'valid_sales.tab')

        sales_import.import_file.attach(
          io: File.open(file_path),
          filename: 'valid_sales.tab',
          content_type: 'text/tab-separated-values'
        )
      end
    end

    trait :with_invalid_file do
      after(:build) do |sales_import|
        file_path = Rails.root.join('spec', 'fixtures', 'files', 'invalid_sales_empty_purchaser.tab')

        sales_import.import_file.attach(
          io: File.open(file_path),
          filename: 'invalid_sales_empty_purchaser.tab',
          content_type: 'text/tab-separated-values'
        )
      end
    end

    trait :with_zero_price_file do
      after(:build) do |sales_import|
        file_path = Rails.root.join('spec', 'fixtures', 'files', 'invalid_sales_zero_price.tab')

        sales_import.import_file.attach(
          io: File.open(file_path),
          filename: 'invalid_sales_zero_price.tab',
          content_type: 'text/tab-separated-values'
        )
      end
    end

    trait :with_empty_file do
      after(:build) do |sales_import|
        file_path = Rails.root.join('spec', 'fixtures', 'files', 'empty_sales.tab')

        sales_import.import_file.attach(
          io: File.open(file_path),
          filename: 'empty_sales.tab',
          content_type: 'text/tab-separated-values'
        )
      end
    end

    trait :with_mixed_file do
      after(:build) do |sales_import|
        file_path = Rails.root.join('spec', 'fixtures', 'files', 'mixed_sales.tab')

        sales_import.import_file.attach(
          io: File.open(file_path),
          filename: 'mixed_sales.tab',
          content_type: 'text/tab-separated-values'
        )
      end
    end
  end
end
