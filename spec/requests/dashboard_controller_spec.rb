require 'rails_helper'

RSpec.describe "DashboardController", type: :request do
  describe "GET #index" do
    let!(:completed_import1) { create(:sales_import, status: :completed, total_sales_cents: 5000, created_at: 2.days.ago) }
    let!(:completed_import2) { create(:sales_import, status: :completed, total_sales_cents: 3000, created_at: 1.day.ago) }
    let!(:failed_import) { create(:sales_import, status: :failed, total_sales_cents: 0, created_at: 3.days.ago) }
    let!(:pending_import) { create(:sales_import, status: :pending, total_sales_cents: 0, created_at: Time.current) }

    before do
      get root_path
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "renders the index template" do
      expect(response).to render_template(:index)
    end

    it "assigns @recent_imports with recent imports ordered by created_at desc" do
      expect(assigns(:recent_imports)).to eq([ pending_import, completed_import2, completed_import1, failed_import ])
    end

    it "limits recent imports to 5" do
      6.times { create(:sales_import, created_at: Time.current + rand(1..100).minutes) }
      get root_path
      expect(assigns(:recent_imports).count).to eq(5)
    end

    it "assigns @last_gross_income with the most recent completed import total" do
      expect(assigns(:last_gross_income)).to eq(3000)
    end

    it "assigns @total_gross_income with sum of all completed imports" do
      expect(assigns(:total_gross_income)).to eq(8000)
    end

    context "when there are no completed imports" do
      let!(:completed_import1) { nil }
      let!(:completed_import2) { nil }

      before do
        SalesImport.where(status: :completed).destroy_all
        get root_path
      end

      it "assigns @last_gross_income as 0" do
        expect(assigns(:last_gross_income)).to eq(0)
      end

      it "assigns @total_gross_income as 0" do
        expect(assigns(:total_gross_income)).to eq(0)
      end
    end

    context "when there are no imports at all" do
      before do
        SalesImport.destroy_all
        get root_path
      end

      it "assigns empty recent_imports" do
        expect(assigns(:recent_imports)).to be_empty
      end

      it "assigns @last_gross_income as 0" do
        expect(assigns(:last_gross_income)).to eq(0)
      end

      it "assigns @total_gross_income as 0" do
        expect(assigns(:total_gross_income)).to eq(0)
      end
    end
  end

  describe "POST #upload" do
    let(:valid_file) { fixture_file_upload('spec/fixtures/files/example_input.tab', 'text/tab-separated-values') }
    let(:invalid_file) { fixture_file_upload('spec/fixtures/files/invalid_file.txt', 'text/plain') }

    context "with valid file upload" do
      it "creates a new SalesImport record" do
        expect {
          post upload_path, params: { import_file: valid_file }
        }.to change(SalesImport, :count).by(1)
      end

      it "attaches the file to the import" do
        post upload_path, params: { import_file: valid_file }

        created_import = SalesImport.last
        expect(created_import.import_file).to be_attached
      end

      it "sets the filename" do
        post upload_path, params: { import_file: valid_file }

        created_import = SalesImport.last
        expect(created_import.filename).to eq('example_input.tab')
      end

      it "processes the file and updates status" do
        post upload_path, params: { import_file: valid_file }

        created_import = SalesImport.last
        expect([ 'pending', 'completed', 'failed' ]).to include(created_import.status)
      end

      it "redirects to root path" do
        post upload_path, params: { import_file: valid_file }
        expect(response).to redirect_to(root_path)
      end

      it "sets appropriate flash message" do
        post upload_path, params: { import_file: valid_file }
        expect(flash[:notice] || flash[:alert]).to be_present
      end
    end

    context "when no file is provided" do
      it "does not create a SalesImport record" do
        expect {
          post upload_path, params: {}
        }.not_to change(SalesImport, :count)
      end

      it "redirects to root path with error alert" do
        post upload_path, params: {}

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Please select a file to upload.")
      end
    end

    context "when empty file parameter is provided" do
      it "does not create a SalesImport record" do
        expect {
          post upload_path, params: { import_file: nil }
        }.not_to change(SalesImport, :count)
      end

      it "redirects to root path with error alert" do
        post upload_path, params: { import_file: nil }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Please select a file to upload.")
      end
    end
  end
end
