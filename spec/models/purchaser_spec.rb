require 'rails_helper'

RSpec.describe Purchaser, type: :model do
  it { should have_many(:sales).dependent(:destroy) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(3) }
    it { should validate_length_of(:name).is_at_most(100) }
  end

  describe "name validation" do
    it 'is invalid without a name' do
      purchaser = Purchaser.new(name: nil)
      expect(purchaser).not_to be_valid
      expect(purchaser.errors[:name]).to include("can't be blank")
    end

    it 'is invalid with a name shorter than 3 characters' do
      purchaser = Purchaser.new(name: 'Jo')
      expect(purchaser).not_to be_valid
      expect(purchaser.errors[:name]).to include('is too short (minimum is 3 characters)')
    end

    it 'is invalid with a name longer than 100 characters' do
      purchaser = Purchaser.new(name: 'a' * 101)
      expect(purchaser).not_to be_valid
      expect(purchaser.errors[:name]).to include('is too long (maximum is 100 characters)')
    end

    it 'is valid with a name between 3 and 50 characters' do
      purchaser = Purchaser.new(name: 'Jonh Doe')
      expect(purchaser).to be_valid
    end

    # it 'is invalid with a duplicate name' do
    #   Purchaser.create!(name: 'Jane Doe')
    #   purchaser = Purchaser.new(name: 'Jane Doe')
    #   expect(purchaser).not_to be_valid
    #   expect(purchaser.errors[:name]).to include('has already been taken')
    # end
  end
end
