require 'rails_helper'

RSpec.describe SalesImports::SalesCreator do
  let(:sales_import) { create(:sales_import) }
  let(:creator) { described_class.new(sales_import) }

  describe '#call' do
    context 'with valid sales data from fixture' do
      let(:parser) { SalesImports::FileParser.new }
      let(:file_path) { Rails.root.join('spec', 'fixtures', 'files', 'valid_sales.tab') }
      let(:file_blob) do
        blob = double('ActiveStorage::Blob')
        allow(blob).to receive(:open).and_yield(File.open(file_path))
        blob
      end
      let(:sales_data) { parser.call(file_blob).value! }

      it 'creates sales successfully and returns Success' do
        result = creator.call(sales_data)

        expect(result).to be_success

        data = result.value!
        expect(data[:total_revenue]).to eq(3550) # (1000*2) + (1550*1)
        expect(data[:processed_count]).to eq(2)

        expect(Sale.count).to eq(2)
        expect(Purchaser.count).to eq(2)
        expect(Item.count).to eq(2)
        expect(Merchant.count).to eq(2)
      end

      it 'creates associated records correctly' do
        creator.call(sales_data)

        expect(Purchaser.find_by(name: 'John Doe')).to be_present
        expect(Purchaser.find_by(name: 'Jane Smith')).to be_present
        expect(Item.find_by(description: 'Test Item')).to be_present
        expect(Item.find_by(description: 'Another Item')).to be_present
        expect(Merchant.find_by(name: 'Test Store', address: '123 Main St')).to be_present
        expect(Merchant.find_by(name: 'Another Store', address: '456 Oak Ave')).to be_present
      end

      it 'reuses existing records' do
        # Create existing records that match the first row in fixture
        existing_purchaser = create(:purchaser, name: 'John Doe')
        existing_item = create(:item, description: 'Test Item')
        existing_merchant = create(:merchant, name: 'Test Store', address: '123 Main St')

        creator.call([ sales_data.first ])

        # Should reuse existing records, not create new ones
        expect(Purchaser.count).to eq(1)
        expect(Item.count).to eq(1)
        expect(Merchant.count).to eq(1)

        sale = Sale.first
        expect(sale.purchaser).to eq(existing_purchaser)
        expect(sale.item).to eq(existing_item)
        expect(sale.merchant).to eq(existing_merchant)
      end
    end

    context 'with invalid sales data from fixture' do
      let(:parser) { SalesImports::FileParser.new }
      let(:file_path) { Rails.root.join('spec', 'fixtures', 'files', 'invalid_sales_empty_purchaser.tab') }
      let(:file_blob) do
        blob = double('ActiveStorage::Blob')
        allow(blob).to receive(:open).and_yield(File.open(file_path))
        blob
      end

      it 'returns Failure when parsing fails due to validation' do
        result = parser.call(file_blob)
        expect(result).to be_failure
        expect(result.failure).to include('Invalid data found')
      end
    end

    context 'with mixed valid and invalid data from fixture' do
      let(:parser) { SalesImports::FileParser.new }
      let(:file_path) { Rails.root.join('spec', 'fixtures', 'files', 'mixed_sales.tab') }
      let(:file_blob) do
        blob = double('ActiveStorage::Blob')
        allow(blob).to receive(:open).and_yield(File.open(file_path))
        blob
      end

      it 'fails parsing due to invalid rows' do
        result = parser.call(file_blob)
        expect(result).to be_failure
        expect(result.failure).to include('Invalid data found')
        expect(result.failure).to include('Row 2')
      end
    end

    context 'with database error' do
      let(:sales_data) do
        [ {
          purchaser_name: 'John Doe',
          item_description: 'Test Item',
          item_price: 1000,
          purchase_count: 2,
          merchant_address: '123 Main St',
          merchant_name: 'Test Store'
        } ]
      end

      it 'handles ActiveRecord errors gracefully' do
        allow(Sale).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Sale.new))

        result = creator.call(sales_data)

        expect(result).to be_failure
        expect(result.failure).to include('All sales failed validation')
      end
    end
  end

  describe '#create_sale' do
    let(:sale_data) do
      {
        purchaser_name: 'John Doe',
        item_description: 'Test Item',
        item_price: 1000,
        purchase_count: 2,
        merchant_address: '123 Main St',
        merchant_name: 'Test Store'
      }
    end

    it 'creates a sale with correct attributes' do
      sale = creator.send(:create_sale, sale_data)

      expect(sale).to be_persisted
      expect(sale.purchase_count).to eq(2)
      expect(sale.item_price_cents).to eq(1000)
      expect(sale.sales_import).to eq(sales_import)
      expect(sale.gross_revenue_cents).to eq(2000)
    end

    it 'returns nil when purchaser creation fails' do
      allow(Purchaser).to receive(:find_or_create_by).and_raise(ActiveRecord::RecordInvalid.new(Purchaser.new))

      sale = creator.send(:create_sale, sale_data)
      expect(sale).to be_nil
    end
  end
end
