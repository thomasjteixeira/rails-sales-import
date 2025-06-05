require 'rails_helper'

RSpec.describe "DashboardController", type: :request do
  describe "GET #index" do
    let!(:completed_import1) { create(:sales_import, :completed, total_sales_cents: 5000, created_at: 2.days.ago) }
    let!(:completed_import2) { create(:sales_import, :completed, total_sales_cents: 3000, created_at: 1.day.ago) }
    let!(:failed_import) { create(:sales_import, :failed, created_at: 3.days.ago) }
    let!(:pending_import) { create(:sales_import, created_at: Time.current) }

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
      6.times { |i| create(:sales_import, created_at: Time.current + (i + 1).minutes) }

      get root_path
      expect(assigns(:recent_imports).count).to eq(5)
    end

    it "includes sales association in recent imports" do
      expect(assigns(:recent_imports).first.association(:sales)).to be_loaded
    end

    it "assigns @last_gross_income with the most recent completed import total" do
      expect(assigns(:last_gross_income)).to eq(completed_import2.total_sales_cents)
    end

    it "assigns @total_gross_income with sum of all completed imports" do
      expect(assigns(:total_gross_income)).to eq(completed_import1.total_sales_cents + completed_import2.total_sales_cents)
    end

    context "when there are no completed imports" do
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
    let(:valid_file) do
      fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'valid_sales.tab'), 'text/tab-separated-values')
    end

    let(:invalid_file) do
      fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'invalid_sales_empty_purchaser.tab'), 'text/tab-separated-values')
    end

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
        expect(created_import.import_file.filename.to_s).to eq('valid_sales.tab')
      end

      it "sets the filename" do
        post upload_path, params: { import_file: valid_file }

        created_import = SalesImport.last
        expect(created_import.filename).to eq('valid_sales.tab')
      end


      it "processes the file successfully" do
        post upload_path, params: { import_file: valid_file }

        created_import = SalesImport.last
        created_import.reload


        expect(created_import.status).to eq('completed')
        expect(created_import.total_sales_cents).to be_positive
      end

      it "creates sales records" do
        expect {
          post upload_path, params: { import_file: valid_file }
        }.to change(Sale, :count).by(2)
      end

      it "creates associated records" do
        expect {
          post upload_path, params: { import_file: valid_file }
        }.to change(Purchaser, :count).by(2)
          .and change(Item, :count).by(2)
          .and change(Merchant, :count).by(2)
      end

      it "redirects to root path with success notice" do
        post upload_path, params: { import_file: valid_file }

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("File uploaded and processed successfully!")
      end
    end

    context "with invalid file (empty purchaser)" do
      it "creates a SalesImport record but marks it as failed" do
        expect {
          post upload_path, params: { import_file: invalid_file }
        }.to change(SalesImport, :count).by(1)

        created_import = SalesImport.last
        created_import.reload
        expect(created_import.status).to eq('failed')
      end

      it "does not create sales records" do
        expect {
          post upload_path, params: { import_file: invalid_file }
        }.not_to change(Sale, :count)
      end

      it "redirects to root path with error alert" do
        post upload_path, params: { import_file: invalid_file }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("Invalid data found")
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

    context "when blank string is provided as file" do
      it "does not create a SalesImport record" do
        expect {
          post upload_path, params: { import_file: "" }
        }.not_to change(SalesImport, :count)
      end

      it "redirects to root path with error alert" do
        post upload_path, params: { import_file: "" }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Please select a file to upload.")
      end
    end

    context "when file attachment fails" do
      before do
        allow_any_instance_of(ActiveStorage::Attached::One).to receive(:attach).and_return(false)
        allow_any_instance_of(ActiveStorage::Attached::One).to receive(:attached?).and_return(false)
      end

      it "creates SalesImport but marks as failed" do
        expect {
          post upload_path, params: { import_file: valid_file }
        }.to change(SalesImport, :count).by(1)

        created_import = SalesImport.last
        expect(created_import.status).to eq('failed')
      end

      it "redirects with attachment error message" do
        post upload_path, params: { import_file: valid_file }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Failed to attach file. Please try again.")
      end
    end

    context "when processor service fails" do
      before do
        allow_any_instance_of(SalesImports::Processor).to receive(:call)
          .and_return(Dry::Monads::Failure("Processing failed: Service error"))
      end

      it "redirects with processor error message" do
        post upload_path, params: { import_file: valid_file }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Processing failed: Service error")
      end
    end
  end
end
