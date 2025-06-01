require 'rails_helper'

RSpec.describe SalesImport::Create, type: :service do
  let(:sales_import) { create(:sales_import) }
  let(:service) { described_class.new(sales_import: sales_import) }

  def attach_import_file(import_record, filename = 'example_input.tab')
    file_path = Rails.root.join('spec', 'fixtures', 'files', filename)
    file = File.open(file_path)

    import_record.import_file.attach(
      io: file,
      filename: filename,
      content_type: 'text/tab-separated-values'
    )
    import_record.reload
    file.close
  end

  describe 'validations' do
    it 'validates presence of sales_import' do
      service = described_class.new(sales_import: nil)
      expect(service).not_to be_valid
      expect(service.errors[:sales_import]).to include("can't be blank")
    end

    context 'when sales_import has no file attached' do
      let(:sales_import) { create(:sales_import, import_file: nil) }

      it 'is invalid' do
        expect(service).not_to be_valid
        expect(service.errors[:sales_import]).to include('must have a file attached')
      end
    end

    context 'when sales_import has a file attached' do
      before { attach_import_file(sales_import) }

      it 'is valid' do
        expect(service).to be_valid
      end
    end
  end

  describe '#call' do
    context 'when service is valid' do
      before do
        attach_import_file(sales_import)
      end

      it 'returns true' do
        expect(service.call).to be true
      end

      it 'changes sales_import status to processing then completed' do
        expect { service.call }
          .to change { sales_import.reload.status }
          .from('pending')
          .to('completed')
      end

      it 'sets the filename on sales_import' do
        service.call
        expect(sales_import.reload.filename).to eq('example_input.tab')
      end

      it 'calculates and sets total_sales_cents' do
        service.call
        sales_import.reload

        expect(sales_import.total_sales_cents).to eq(10295)
      end

      it 'creates purchaser records' do
        expect { service.call }
          .to change(Purchaser, :count).by(4)

        expect(Purchaser.pluck(:name)).to contain_exactly(
          'João Silva', 'Amy Pond', 'Marty McFly', 'Snake Plissken'
        )
      end

      it 'creates item records' do
        expect { service.call }
          .to change(Item, :count).by(3)

        expect(Item.pluck(:description)).to contain_exactly(
          'Pepperoni Pizza Slice', 'Cute T-Shirt', 'Cool Sneakers'
        )
      end

      it 'creates merchant records' do
        expect { service.call }
          .to change(Merchant, :count).by(3)

        merchants = Merchant.all
        expect(merchants.map(&:name)).to contain_exactly(
          "Bob's Pizza", "Tom's Awesome Shop", 'Sneaker Store Emporium'
        )
        expect(merchants.map(&:address)).to contain_exactly(
          '987 Fake St', '456 Unreal Rd', '123 Fake St'
        )
      end

      it 'creates sale records' do
        expect { service.call }
          .to change(Sale, :count).by(5)

        sales = Sale.all
        expect(sales.map(&:purchase_count)).to contain_exactly(2, 5, 1, 4, 1)
        expect(sales.map(&:item_price_cents)).to contain_exactly(1000, 1000, 500, 500, 795)
      end

      it 'associates all sales with the sales_import' do
        service.call
        expect(sales_import.sales.count).to eq(5)
      end
    end

    context 'when service is invalid' do
      let(:sales_import) { create(:sales_import, import_file: nil) }

      it 'returns false' do
        expect(service.call).to be false
      end

      it 'does not change sales_import status' do
        expect { service.call }
          .not_to change { sales_import.reload.status }
      end
    end

    context 'when an error occurs during processing' do
      before do
        attach_import_file(sales_import)
        allow(SmarterCSV).to receive(:process).and_raise(StandardError, 'CSV parsing error')
      end

      it 'returns false' do
        expect(service.call).to be false
      end

      it 'sets sales_import status to failed' do
        service.call
        expect(sales_import.reload.status).to eq('failed')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with('SalesImport failed: CSV parsing error')
        service.call
      end
    end

    # context 'with duplicate data' do
    # context 'with empty rows' do
  end

  describe 'private methods' do
    describe '#parse_price' do
      it 'converts amounts to cents' do
        expect(service.send(:parse_price, '10.0')).to eq(1000)
        expect(service.send(:parse_price, '5.50')).to eq(550)
        expect(service.send(:parse_price, '0.99')).to eq(99)
      end

      it 'handles blank values' do
        expect(service.send(:parse_price, '')).to eq(0)
        expect(service.send(:parse_price, nil)).to eq(0)
      end
    end
  end
end
