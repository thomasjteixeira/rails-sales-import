require 'rails_helper'

RSpec.describe SampleFilesController, type: :request do
  describe 'GET /samples/:filename' do
    let(:valid_filename) { 'example_input.tab' }
    let(:file_path) { Rails.root.join('spec', 'fixtures', 'files', valid_filename) }

    before do
      FileUtils.mkdir_p(Rails.root.join('spec', 'fixtures', 'files'))


      unless File.exist?(file_path)
        content = <<~TSV
          "purchaser name"	"item description"	"item price"	"purchase count"	"merchant address"	"merchant name"
          "João Silva"	"Pepperoni Pizza Slice"	10.0	2	"987 Fake St"	"Bob's Pizza"
          "Amy Pond"	"Cute T-Shirt"	10.0	5	"456 Unreal Rd"	"Tom's Awesome Shop"
          "Marty McFly"	"Cool Sneakers"	5.0	1	"123 Fake St"	"Sneaker Store Emporium"
          "Snake Plissken"	"Cool Sneakers"	5.0	4	"123 Fake St"	"Sneaker Store Emporium"
          "João Silva"	"Cute T-Shirt"	7.95	1	"456 Unreal Rd"	"Tom's Awesome Shop"
        TSV
        File.write(file_path, content)
      end
    end

    it 'returns the file when it exists and filename is valid' do
      get "/samples/#{valid_filename}"

      expect(response).to have_http_status(:ok)
      expect(response.headers['Content-Type']).to eq('text/tab-separated-values')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include(valid_filename)
    end

    it 'returns not found when file does not exist' do
      get '/samples/nonexistent.tsv'

      expect(response).to have_http_status(:not_found)
    end
  end
end
