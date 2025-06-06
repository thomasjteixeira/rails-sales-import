require 'rails_helper'

RSpec.describe Item, type: :model do
  it { should have_many(:sales).dependent(:destroy) }

  describe 'validations' do
    it { should validate_presence_of(:description) }
    it { should validate_length_of(:description).is_at_least(3) }
    it { should validate_length_of(:description).is_at_most(50) }
  end

  describe 'description validation' do
    it 'is invalid without a description' do
      item = Item.new(description: nil)
      expect(item).not_to be_valid
      expect(item.errors[:description]).to include("can't be blank")
    end

    it 'is invalid with a description less than 3 characters' do
      item = Item.new(description: 'ab')
      expect(item).not_to be_valid
      expect(item.errors[:description]).to include("is too short (minimum is 3 characters)")
    end

    it 'is invalid with a description more than 50 characters' do
      item = Item.new(description: 'a' * 51)
      expect(item).not_to be_valid
      expect(item.errors[:description]).to include("is too long (maximum is 50 characters)")
    end

    it 'is valid with a description between 3 and 50 characters' do
      item = Item.new(description: 'Carrot')
      expect(item).to be_valid
    end
  end
end
