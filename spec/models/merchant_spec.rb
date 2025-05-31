require 'rails_helper'

RSpec.describe Merchant, type: :model do
  it { should have_many(:sales).dependent(:destroy) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(3) }
    it { should validate_length_of(:name).is_at_most(100) }
  end

  describe 'name validation' do
    it 'is invalid without a name' do
      merchant = Merchant.new(name: nil, address: '123 Main St, Springfield')
      expect(merchant).not_to be_valid
      expect(merchant.errors[:name]).to include("can't be blank")
    end

    it 'is invalid with a name shorter than 3 characters' do
      merchant = Merchant.new(name: 'AB', address: '123 Main St, Springfield')
      expect(merchant).not_to be_valid
      expect(merchant.errors[:name]).to include('is too short (minimum is 3 characters)')
    end

    it 'is invalid with a name longer than 100 characters' do
      merchant = Merchant.new(name: 'A' * 101, address: '123 Main St, Springfield')
      expect(merchant).not_to be_valid
      expect(merchant.errors[:name]).to include('is too long (maximum is 100 characters)')
    end

    it 'is valid with a name between 3 and 100 characters' do
      merchant = Merchant.new(name: 'Valid Merchant Name', address: '123 Main St, Springfield')
      expect(merchant).to be_valid
    end
  end

  describe 'address validation' do
    it 'is invalid without an address' do
      merchant = Merchant.new(name: 'John', address: nil)
      expect(merchant).not_to be_valid
      expect(merchant.errors[:address]).to include("can't be blank")
    end

    it 'is invalid with an address shorter than 3 characters' do
      merchant = Merchant.new(name: 'John', address: 'AB')
      expect(merchant).not_to be_valid
      expect(merchant.errors[:address]).to include('is too short (minimum is 3 characters)')
    end

    it 'is invalid with an address longer than 255 characters' do
      merchant = Merchant.new(name: 'John', address: 'A' * 256)
      expect(merchant).not_to be_valid
      expect(merchant.errors[:address]).to include('is too long (maximum is 255 characters)')
    end

    it 'is valid with an address between 3 and 255 characters' do
      merchant = Merchant.new(name: 'John', address: '123 Main St, Springfield')
      expect(merchant).to be_valid
    end
  end
end
