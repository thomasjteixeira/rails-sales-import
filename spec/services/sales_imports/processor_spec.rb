require 'rails_helper'

RSpec.describe SalesImports::Processor do
  let(:sales_import) { create(:sales_import) }
  let(:processor) { described_class.new(sales_import) }

  describe '#call' do
    context 'with valid sales import and file' do
      let(:sales_import) { create(:sales_import, :with_file) }

      it 'processes the import successfully' do
        result = processor.call

        expect(result).to be_success

        import = result.value!
        expect(import.status).to eq('completed')
        expect(import.total_sales_cents).to eq(3550) # (10.00*2) + (15.50*1) = 35.50
        expect(import.sales.count).to eq(2)
      end

      it 'updates import status through the process' do
        expect { processor.call }.to change { sales_import.reload.status }
          .from('pending').to('completed')
      end

      it 'creates associated records' do
        expect { processor.call }.to change { Sale.count }.by(2)
          .and change { Purchaser.count }.by(2)
          .and change { Item.count }.by(2)
          .and change { Merchant.count }.by(2)
      end

      it 'sets the correct filename' do
        processor.call
        sales_import.reload
        expect(sales_import.filename).to eq('valid_sales.tab')
      end
    end

    context 'with invalid file data (empty purchaser)' do
      let(:sales_import) { create(:sales_import, :with_invalid_file) }

      it 'fails processing and marks import as failed' do
        result = processor.call

        expect(result).to be_failure
        expect(result.failure).to include('Invalid data found')
        expect(result.failure).to include('is required')

        sales_import.reload
        expect(sales_import.status).to eq('failed')
      end

      it 'does not create any sales' do
        expect { processor.call }.not_to change { Sale.count }
      end
    end

    context 'with zero price file' do
      let(:sales_import) { create(:sales_import, :with_zero_price_file) }

      it 'fails processing due to invalid price' do
        result = processor.call

        expect(result).to be_failure
        expect(result.failure).to include('item price must be greater than 0')

        sales_import.reload
        expect(sales_import.status).to eq('failed')
      end
    end

    context 'with empty file' do
      let(:sales_import) { create(:sales_import, :with_empty_file) }

      it 'fails processing due to no data' do
        result = processor.call

        expect(result).to be_failure
        expect(result.failure).to eq('No valid data found in file')

        sales_import.reload
        expect(sales_import.status).to eq('failed')
      end
    end

    context 'with mixed valid and invalid data' do
      let(:sales_import) { create(:sales_import, :with_mixed_file) }

      it 'fails processing due to invalid rows' do
        result = processor.call

        expect(result).to be_failure
        expect(result.failure).to include('Invalid data found')

        sales_import.reload
        expect(sales_import.status).to eq('failed')
      end
    end

    context 'without attached file' do
      it 'returns Failure with appropriate message' do
        result = processor.call

        expect(result).to be_failure
        expect(result.failure).to eq('No file attached')
      end

      it 'does not change import status' do
        expect { processor.call }.not_to change { sales_import.reload.status }
      end
    end

    context 'with nil sales_import' do
      let(:processor) { described_class.new(nil) }

      it 'returns Failure with appropriate message' do
        result = processor.call

        expect(result).to be_failure
        expect(result.failure).to eq('Sales import not found')
      end
    end

    context 'when file parsing fails' do
      let(:sales_import) { create(:sales_import, :with_file) }

      before do
        allow_any_instance_of(SalesImports::FileParser).to receive(:call)
          .and_return(Dry::Monads::Failure('Parsing error'))
      end

      it 'marks import as failed and returns failure' do
        result = processor.call

        expect(result).to be_failure
        expect(result.failure).to eq('Parsing error')

        sales_import.reload
        expect(sales_import.status).to eq('failed')
      end
    end

    context 'when sales creation fails' do
      let(:sales_import) { create(:sales_import, :with_file) }

      before do
        allow_any_instance_of(SalesImports::SalesCreator).to receive(:call)
          .and_return(Dry::Monads::Failure('Creation error'))
      end

      it 'marks import as failed and returns failure' do
        result = processor.call

        expect(result).to be_failure
        expect(result.failure).to eq('Creation error')

        sales_import.reload
        expect(sales_import.status).to eq('failed')
      end
    end

    context 'when unexpected error occurs' do
      let(:sales_import) { create(:sales_import, :with_file) }

      before do
        allow_any_instance_of(SalesImports::FileParser).to receive(:call)
          .and_raise(StandardError.new('Unexpected error'))
      end

      it 'handles the error gracefully and marks import as failed' do
        result = processor.call

        expect(result).to be_failure
        expect(result.failure).to include('Processing failed: Unexpected error')

        sales_import.reload
        expect(sales_import.status).to eq('failed')
      end
    end
  end

  describe '#update_import_status' do
    it 'updates the status using update_column' do
      expect(sales_import).to receive(:update_column).with(:status, SalesImport.statuses[:processing])

      processor.send(:update_import_status, :processing)
    end

    it 'handles errors gracefully' do
      allow(sales_import).to receive(:update_column).and_raise(StandardError.new('DB error'))

      expect(Rails.logger).to receive(:error).with(/Failed to update sales_import status/)

      processor.send(:update_import_status, :processing)
    end
  end
end
