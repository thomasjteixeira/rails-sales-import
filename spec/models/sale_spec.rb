require 'rails_helper'

RSpec.describe Sale, type: :model do
  subject(:sale) { build(:sale) }

  describe 'associations' do
    it { should belong_to(:purchaser) }
    it { should belong_to(:item) }
    it { should belong_to(:merchant) }
    it { should belong_to(:sales_import) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:purchase_count) }
    it { is_expected.to validate_numericality_of(:purchase_count).is_greater_than(0) }

    it { is_expected.to validate_presence_of(:item_price_cents) }
    it { is_expected.to validate_numericality_of(:item_price_cents).is_greater_than(0) }
  end

  describe 'callbacks' do
    describe '#calculate_gross_revenue' do
      context 'when both purchase_count and item_price_cents are present' do
        it 'calculates gross revenue before validation' do
          sale = build(:sale, purchase_count: 3, item_price_cents: 1000, gross_revenue_cents: nil)

          expect { sale.valid? }.to change(sale, :gross_revenue_cents).from(nil).to(3000)
        end

        it 'recalculates gross revenue even if already set' do
          sale = build(:sale, purchase_count: 2, item_price_cents: 500, gross_revenue_cents: 9999)

          expect { sale.valid? }.to change(sale, :gross_revenue_cents).from(9999).to(1000)
        end
      end

      context 'when purchase_count is missing' do
        it 'does not calculate gross revenue' do
          sale = build(:sale, purchase_count: nil, item_price_cents: 1000, gross_revenue_cents: 5000)

          expect { sale.valid? }.not_to change(sale, :gross_revenue_cents)
          expect(sale.gross_revenue_cents).to eq(5000)
        end
      end

      context 'when item_price_cents is missing' do
        it 'does not calculate gross revenue' do
          sale = build(:sale, purchase_count: 3, item_price_cents: nil, gross_revenue_cents: 5000)

          expect { sale.valid? }.not_to change(sale, :gross_revenue_cents)
          expect(sale.gross_revenue_cents).to eq(5000)
        end
      end

      context 'when both purchase_count and item_price_cents are missing' do
        it 'does not calculate gross revenue' do
          sale = build(:sale, purchase_count: nil, item_price_cents: nil, gross_revenue_cents: 5000)

          expect { sale.valid? }.not_to change(sale, :gross_revenue_cents)
          expect(sale.gross_revenue_cents).to eq(5000)
        end
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:sale)).to be_valid
    end

    it 'creates a valid record' do
      expect(create(:sale)).to be_persisted
    end
  end
end
