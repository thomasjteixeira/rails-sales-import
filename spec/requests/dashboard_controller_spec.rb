require 'rails_helper'

RSpec.describe "DashboardController", type: :request do
  include ActiveJob::TestHelper

  around(:each) do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

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

    context "when no file is provided" do
      it "does not create SalesImport or enqueue jobs" do
        expect {
          post upload_path, params: {}
        }.not_to change(SalesImport, :count)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Please select a file to upload.")
        expect(enqueued_jobs).to be_empty
      end
    end

    context "when blank file parameter is provided" do
      it "does not create SalesImport or enqueue jobs" do
        expect {
          post upload_path, params: { import_file: nil }
        }.not_to change(SalesImport, :count)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Please select a file to upload.")
        expect(enqueued_jobs).to be_empty
      end
    end

    context "with valid file upload" do
      it "creates SalesImport, attaches file, and enqueues processing job" do
        expect {
          post upload_path, params: { import_file: valid_file }
        }.to change(SalesImport, :count).by(1)
         .and have_enqueued_job(SalesImportProcessingJob).with(kind_of(Integer))

        created_import = SalesImport.last
        expect(created_import.status).to eq('pending')
        expect(created_import.filename).to eq('valid_sales.tab')
        expect(created_import.import_file).to be_attached
        expect(created_import.import_file.filename.to_s).to eq('valid_sales.tab')

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("File uploaded successfully! Processing in background...")
      end
    end

    context "when file attachment fails" do
      before do
        allow_any_instance_of(ActiveStorage::Attached::One).to receive(:attach).and_return(false)
        allow_any_instance_of(ActiveStorage::Attached::One).to receive(:attached?).and_return(false)
      end

      it "creates SalesImport but marks as failed and does not enqueue jobs" do
        expect {
          post upload_path, params: { import_file: valid_file }
        }.to change(SalesImport, :count).by(1)

        created_import = SalesImport.last
        expect(created_import.status).to eq('failed')
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Failed to attach file. Please try again.")
        expect(enqueued_jobs).to be_empty
      end
    end

    context "when job enqueuing fails" do
      before do
        allow(SalesImportProcessingJob).to receive(:perform_later).and_raise(StandardError, "Job queue error")
        allow(Rails.logger).to receive(:error)
      end

      it "marks SalesImport as failed and logs error" do
        post upload_path, params: { import_file: valid_file }

        created_import = SalesImport.last
        expect(created_import.status).to eq('failed')
        expect(Rails.logger).to have_received(:error)
          .with("Failed to enqueue processing job for sales import #{created_import.id}: Job queue error")
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Failed to start processing. Please try again.")
      end
    end
  end

  describe "integration workflow" do
    let(:valid_file) do
      fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'valid_sales.tab'), 'text/tab-separated-values')
    end

    it "processes complete upload to job execution workflow" do
      # Upload file
      post upload_path, params: { import_file: valid_file }

      # Verify initial state
      sales_import = SalesImport.last
      expect(sales_import.status).to eq('pending')
      expect(enqueued_jobs.size).to eq(1)
      expect(enqueued_jobs.first['job_class']).to eq('SalesImportProcessingJob')
      expect(enqueued_jobs.first['arguments']).to eq([ sales_import.id ])

      # Mock successful processing
      processor_service = instance_double(SalesImports::Processor)
      allow(SalesImports::Processor).to receive(:new).with(sales_import).and_return(processor_service)
      allow(processor_service).to receive(:call).and_return(Dry::Monads::Success())
      allow(Rails.logger).to receive(:info)

      # Execute enqueued jobs
      perform_enqueued_jobs

      # Verify job execution
      expect(performed_jobs.size).to eq(1)
      expect(performed_jobs.first['job_class']).to eq('SalesImportProcessingJob')
      expect(Rails.logger).to have_received(:info)
        .with("Sales import #{sales_import.id} processed successfully")
    end
  end
end
