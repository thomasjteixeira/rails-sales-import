require 'rails_helper'

RSpec.describe SalesImport, type: :model do
  describe 'associations' do
    it { should have_many(:sales).dependent(:destroy) }
    it { should have_one_attached(:import_file) }
  end

  describe 'validations' do
    context 'on update' do
      subject { create(:sales_import) }

      it { should validate_presence_of(:total_sales_cents).on(:update) }
      it { should validate_numericality_of(:total_sales_cents).is_greater_than_or_equal_to(0).on(:update) }
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status).
    with_values(pending: 0, processing: 1, completed: 2, failed: 3)
    .with_prefix(:status) }

    it 'defaults to pending status' do
      sales_import = SalesImport.new
      expect(sales_import.status).to eq('pending')
    end

    it 'uses status prefix' do
      sales_import = create(:sales_import, status: :completed)
      expect(sales_import.status_completed?).to be true
    end
  end

  describe 'scopes' do
    let!(:completed_import) { create(:sales_import, :completed, total_sales_cents: 100, created_at: 3.days.ago) }
    let!(:failed_import) { create(:sales_import, :failed, total_sales_cents: 200, created_at: 1.day.ago) }
    let!(:pending_import) { create(:sales_import, total_sales_cents: 300, created_at: 2.days.ago) }

    describe '.successful' do
      it 'returns only completed imports' do
        expect(SalesImport.successful).to contain_exactly(completed_import)
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        expect(SalesImport.recent.first).to eq(failed_import) # Most recent
      end
    end
  end

  describe '#revenue_in_reais' do
    it 'converts cents to reais' do
      sales_import = create(:sales_import, total_sales_cents: 2550)
      expect(sales_import.revenue_in_reais).to eq(25.50)
    end
  end

  describe '#sales_count' do
    it 'returns the number of associated sales' do
      sales_import = create(:sales_import)
      create_list(:sale, 3, sales_import: sales_import)

      expect(sales_import.sales_count).to eq(3)
    end

    it 'returns 0 when no sales are associated' do
      sales_import = create(:sales_import)
      expect(sales_import.sales_count).to eq(0)
    end
  end

  describe '.last_gross_income' do
    let!(:older_completed) { create(:sales_import, :completed, total_sales_cents: 1000, created_at: 2.days.ago) }
    let!(:newer_completed) { create(:sales_import, :completed, total_sales_cents: 2000, created_at: 1.day.ago) }
    let!(:failed_import) { create(:sales_import, :failed, total_sales_cents: 5000, created_at: Time.current) }

    it 'returns the total from most recent completed import' do
      expect(SalesImport.last_gross_income).to eq(2000)
    end

    it 'ignores failed imports even if more recent' do
      expect(SalesImport.last_gross_income).not_to eq(5000)
    end

    it 'returns 0 when no completed imports exist' do
      SalesImport.where(status: :completed).destroy_all
      expect(SalesImport.last_gross_income).to eq(0)
    end
  end

  describe '.total_gross_income' do
    let!(:completed1) { create(:sales_import, :completed, total_sales_cents: 1000) }
    let!(:completed2) { create(:sales_import, :completed, total_sales_cents: 2000) }
    let!(:failed_import) { create(:sales_import, :failed, total_sales_cents: 5000) }
    let!(:pending_import) { create(:sales_import, total_sales_cents: 3000) }

    it 'sums only completed imports' do
      expect(SalesImport.total_gross_income).to eq(3000) # 1000 + 2000
    end

    it 'returns 0 when no completed imports exist' do
      SalesImport.where(status: :completed).destroy_all
      expect(SalesImport.total_gross_income).to eq(0)
    end
  end

  describe '.recent_imports' do
    let!(:import1) { create(:sales_import, created_at: 3.days.ago) }
    let!(:import2) { create(:sales_import, created_at: 2.days.ago) }
    let!(:import3) { create(:sales_import, created_at: 1.day.ago) }

    it 'returns recent imports ordered by created_at desc' do
      result = SalesImport.recent_imports(2)
      expect(result).to eq([ import3, import2 ])
    end


    it 'defaults to limit of 5' do
      6.times { create(:sales_import) }
      result = SalesImport.recent_imports
      expect(result.count).to eq(5)
    end

    it 'accepts custom limit' do
      result = SalesImport.recent_imports(2)
      expect(result.count).to eq(2)
    end
  end

  describe 'file attachment' do
    it 'can attach a file' do
      sales_import = create(:sales_import)
      file_content = "test content"

      sales_import.import_file.attach(
        io: StringIO.new(file_content),
        filename: 'test.tsv',
        content_type: 'text/tab-separated-values'
      )

      expect(sales_import.import_file).to be_attached
      expect(sales_import.import_file.filename.to_s).to eq('test.tsv')
    end
  end

  describe 'dependent destroy' do
    it 'destroys associated sales when import is destroyed' do
      sales_import = create(:sales_import)
      sale = create(:sale, sales_import:)

      expect { sales_import.destroy }.to change { Sale.count }.by(-1)
      expect { sale.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.calculate_statistics' do
    let!(:completed_imports) { create_list(:sales_import, 3, :completed, total_sales_cents: 1000) }
    let!(:failed_imports) { create_list(:sales_import, 2, :failed) }
    let!(:pending_imports) { create_list(:sales_import, 1) }

    subject { SalesImport.calculate_statistics }

    it 'returns a hash with statistics' do
      expect(subject).to be_a(Hash)
    end

    it 'returns correct total imports count' do
      expect(subject[:total_imports]).to eq(6) # 3 + 2 + 1
    end

    it 'returns correct successful imports count' do
      expect(subject[:successful_imports]).to eq(3)
    end

    it 'returns correct failed imports count' do
      expect(subject[:failed_imports]).to eq(2)
    end

    it 'returns correct pending imports count' do
      expect(subject[:pending_imports]).to eq(1)
    end

    it 'returns correct total gross income' do
      expect(subject[:total_gross_income]).to eq(3000) # 3 * 1000
    end

    context 'when no imports exist' do
      before { SalesImport.destroy_all }

      it 'returns zeros for all statistics' do
        expect(subject[:total_imports]).to eq(0)
        expect(subject[:successful_imports]).to eq(0)
        expect(subject[:failed_imports]).to eq(0)
        expect(subject[:pending_imports]).to eq(0)
        expect(subject[:total_gross_income]).to eq(0)
      end
    end

    context 'when no successful imports exist' do
      before { SalesImport.where(status: :completed).destroy_all }

      it 'returns zero for gross income' do
        expect(subject[:total_gross_income]).to eq(0)
      end

      it 'still counts other statuses correctly' do
        expect(subject[:failed_imports]).to eq(2)
        expect(subject[:pending_imports]).to eq(1)
        expect(subject[:total_imports]).to eq(3)
      end
    end

    context 'with mixed total_sales_cents values' do
      before do
        SalesImport.destroy_all
        create(:sales_import, :completed, total_sales_cents: 500)
        create(:sales_import, :completed, total_sales_cents: 1500)
        create(:sales_import, :failed, total_sales_cents: 2000) # Should not be counted
      end

      it 'sums only successful imports total_sales_cents' do
        expect(subject[:total_gross_income]).to eq(2000) # 500 + 1500
        expect(subject[:successful_imports]).to eq(2)
      end
    end
  end
end
