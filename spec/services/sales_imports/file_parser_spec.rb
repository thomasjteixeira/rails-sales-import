require 'rails_helper'

RSpec.describe SalesImports::FileParser do
  let(:parser) { described_class.new }

  describe '#call' do
    context 'with valid TSV data' do
      let(:file_path) { Rails.root.join('spec', 'fixtures', 'files', 'valid_sales.tab') }
      let(:file_blob) do
        blob = double('ActiveStorage::Blob')
        allow(blob).to receive(:open).and_yield(File.open(file_path))
        blob
      end

      it 'returns Success with parsed data' do
        result = parser.call(file_blob)

        expect(result).to be_success
        parsed_data = result.value!

        expect(parsed_data.size).to eq(2)

        first_row = parsed_data.first
        expect(first_row[:purchaser_name]).to eq('John Doe')
        expect(first_row[:item_description]).to eq('Test Item')
        expect(first_row[:item_price]).to eq(1000) # 10.00 * 100
        expect(first_row[:purchase_count]).to eq(2)
        expect(first_row[:merchant_address]).to eq('123 Main St')
        expect(first_row[:merchant_name]).to eq('Test Store')

        second_row = parsed_data.second
        expect(second_row[:purchaser_name]).to eq('Jane Smith')
        expect(second_row[:item_description]).to eq('Another Item')
        expect(second_row[:item_price]).to eq(1550) # 15.50 * 100
        expect(second_row[:purchase_count]).to eq(1)
      end
    end

    context 'with invalid data (empty purchaser name)' do
      let(:file_path) { Rails.root.join('spec', 'fixtures', 'files', 'invalid_sales_empty_purchaser.tab') }
      let(:file_blob) do
        blob = double('ActiveStorage::Blob')
        allow(blob).to receive(:open).and_yield(File.open(file_path))
        blob
      end

      it 'returns Failure with validation errors' do
        result = parser.call(file_blob)

        expect(result).to be_failure
        expect(result.failure).to include('Invalid data found')
        expect(result.failure).to include('Row 2')
        expect(result.failure).to include('name is required')
      end
    end

    context 'with invalid data (zero price)' do
      let(:file_path) { Rails.root.join('spec', 'fixtures', 'files', 'invalid_sales_zero_price.tab') }
      let(:file_blob) do
        blob = double('ActiveStorage::Blob')
        allow(blob).to receive(:open).and_yield(File.open(file_path))
        blob
      end

      it 'returns Failure with price validation error' do
        result = parser.call(file_blob)

        expect(result).to be_failure
        expect(result.failure).to include('item price must be greater than 0')
      end
    end

    context 'with file processing error' do
      let(:file_blob) do
        blob = double('ActiveStorage::Blob')
        allow(blob).to receive(:open).and_raise(StandardError.new('File read error'))
        blob
      end

      it 'returns Failure with error message' do
        result = parser.call(file_blob)

        expect(result).to be_failure
        expect(result.failure).to include('Failed to parse file')
      end
    end

    context 'with empty file' do
      let(:file_path) { Rails.root.join('spec', 'fixtures', 'files', 'empty_sales.tab') }
      let(:file_blob) do
        blob = double('ActiveStorage::Blob')
        allow(blob).to receive(:open).and_yield(File.open(file_path))
        blob
      end

      it 'returns Success with empty array' do
        result = parser.call(file_blob)

        expect(result).to be_success
        expect(result.value!).to be_empty
      end
    end

    context 'with mixed valid and invalid data' do
      let(:file_path) { Rails.root.join('spec', 'fixtures', 'files', 'mixed_sales.tab') }
      let(:file_blob) do
        blob = double('ActiveStorage::Blob')
        allow(blob).to receive(:open).and_yield(File.open(file_path))
        blob
      end

      it 'returns Failure with details about invalid rows' do
        result = parser.call(file_blob)

        expect(result).to be_failure
        expect(result.failure).to include('Invalid data found')
        expect(result.failure).to include('Row 2')
        expect(result.failure).to include('name is required')
      end
    end
  end

  describe '#parse_price' do
    it 'converts numeric values to cents' do
      expect(parser.send(:parse_price, 10.50)).to eq(1050)
      expect(parser.send(:parse_price, 5)).to eq(500)
    end

    it 'converts string values to cents' do
      expect(parser.send(:parse_price, '10.50')).to eq(1050)
      expect(parser.send(:parse_price, '5')).to eq(500)
    end

    it 'returns 0 for blank values' do
      expect(parser.send(:parse_price, nil)).to eq(0)
      expect(parser.send(:parse_price, '')).to eq(0)
    end
  end

  describe '#sanitize_string' do
    it 'strips whitespace' do
      expect(parser.send(:sanitize_string, '  test  ')).to eq('test')
    end

    it 'returns nil for empty strings' do
      expect(parser.send(:sanitize_string, '')).to be_nil
      expect(parser.send(:sanitize_string, '   ')).to be_nil
    end

    it 'returns nil for nil input' do
      expect(parser.send(:sanitize_string, nil)).to be_nil
    end
  end
end
