require 'rails_helper'

RSpec.describe ImportHistoryController, type: :request do
  describe 'GET #index' do
    let!(:oldest_import) { create(:sales_import, :completed, total_sales_cents: 500, created_at: 3.days.ago) }
    let!(:newest_import) { create(:sales_import, :completed, total_sales_cents: 500, created_at: Time.current) }
    let!(:failed_import) { create(:sales_import, :failed, created_at: 2.days.ago) }
    let!(:pending_import) { create(:sales_import, created_at: 1.day.ago) }

    before { get import_history_index_path }

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'renders the index template' do
      expect(response).to render_template(:index)
    end

    it 'assigns @imports with imports ordered by created_at desc' do
      imports = assigns(:imports)
      expect(imports.count).to eq(4)
      expect(imports.map(&:id)).to eq([ newest_import.id, pending_import.id, failed_import.id, oldest_import.id ])
    end

    it 'includes sales association in imports' do
      imports = assigns(:imports)
      expect(imports.first.association(:sales)).to be_loaded
    end

    it 'assigns @statistics with calculated statistics' do
      stats = assigns(:statistics)

      expect(stats).to be_a(Hash)
      expect(stats[:total_imports]).to eq(4)
      expect(stats[:successful_imports]).to eq(2)
      expect(stats[:failed_imports]).to eq(1)
      expect(stats[:pending_imports]).to eq(1)
      expect(stats[:total_gross_income]).to eq(1000)
    end

    context 'when no imports exist' do
      before do
        SalesImport.destroy_all
        get import_history_index_path
      end

      it 'assigns empty imports' do
        expect(assigns(:imports)).to be_empty
      end

      it 'assigns zero statistics' do
        stats = assigns(:statistics)
        expect(stats[:total_imports]).to eq(0)
        expect(stats[:successful_imports]).to eq(0)
        expect(stats[:total_gross_income]).to eq(0)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:sales_import) { create(:sales_import, :completed, filename: 'valid_sales.tab') }

    context 'with valid import' do
      it 'destroys the import' do
        expect {
          delete import_history_path(sales_import)
        }.to change(SalesImport, :count).by(-1)
      end

      it 'redirects to import history with success notice' do
        delete import_history_path(sales_import)

        expect(response).to redirect_to(import_history_index_path)
        expect(flash[:notice]).to eq("Import 'valid_sales.tab' was successfully deleted.")
      end

      it 'destroys associated sales due to dependent: :destroy' do
        create_list(:sale, 3, sales_import: sales_import)

        expect {
          delete import_history_path(sales_import)
        }.to change(Sale, :count).by(-3)
      end
    end

    context 'with non-existent import' do
      it 'redirects with error alert when import not found' do
        delete import_history_path(id: 999999)

        expect(response).to redirect_to(import_history_index_path)
        expect(flash[:alert]).to eq('Import not found.')
      end

      it 'does not change import count' do
        expect {
          delete import_history_path(id: 999999)
        }.not_to change(SalesImport, :count)
      end
    end

    context 'when destroy fails' do
      before do
        allow_any_instance_of(SalesImport).to receive(:destroy!)
          .and_raise(StandardError.new('Database constraint violation'))
      end

      it 'redirects with error alert' do
        delete import_history_path(sales_import)

        expect(response).to redirect_to(import_history_index_path)
        expect(flash[:alert]).to eq('Failed to delete import: Database constraint violation')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error)
          .with(/Failed to delete import #{sales_import.id}: Database constraint violation/)

        delete import_history_path(sales_import)
      end

      it 'does not destroy the import' do
        expect {
          delete import_history_path(sales_import)
        }.not_to change(SalesImport, :count)
      end
    end

    context 'when import has no filename' do
      let!(:sales_import) { create(:sales_import, filename: nil) }

      it 'handles nil filename gracefully in success message' do
        delete import_history_path(sales_import)

        expect(flash[:notice]).to eq("Import '' was successfully deleted.")
      end
    end
  end

  describe 'error handling in set_import' do
    it 'handles ActiveRecord::RecordNotFound gracefully' do
      # This test verifies the before_action works correctly
      expect {
        delete import_history_path(id: 999999)
      }.not_to raise_error

      expect(response).to redirect_to(import_history_index_path)
      expect(flash[:alert]).to eq('Import not found.')
    end
  end
end
