require 'rails_helper'

RSpec.describe SalesImport, type: :model do
  describe 'associations' do
    it { should have_many(:sales).dependent(:destroy) }
  end

  describe 'enum' do
    it { should define_enum_for(:status).with_values(pending: 0, processing: 1, completed: 2, failed: 3).with_prefix(true) }

    it 'has default status set to pending' do
      sales_import = described_class.new
      expect(sales_import.status).to eq('pending')
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:filename).on(:update) }
    it { should validate_presence_of(:total_sales_cents) }
    it { should validate_numericality_of(:total_sales_cents).is_greater_than_or_equal_to(0) }
  end
end
