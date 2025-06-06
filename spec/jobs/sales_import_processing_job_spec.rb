require 'rails_helper'

RSpec.describe SalesImportProcessingJob, type: :job do
  include ActiveJob::TestHelper

  before do
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    clear_performed_jobs
  end

  let!(:sales_import) { create(:sales_import, :pending) }
  let(:processor_service) { instance_double(SalesImports::Processor) }

  before do
    allow(SalesImports::Processor).to receive(:new).with(sales_import).and_return(processor_service)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
    allow(Rails.logger).to receive(:warn)
  end

  describe 'job configuration' do
    it 'is queued on the default queue' do
      expect(described_class.queue_name).to eq('default')
    end

    it 'enqueues the job correctly with arguments' do
      expect {
        described_class.perform_later(sales_import.id)
      }.to have_enqueued_job(described_class).with(sales_import.id).on_queue('default')
      expect(enqueued_jobs.size).to eq(1)
    end
  end

  describe '#perform' do
    context 'when processing is successful' do
      before do
        allow(processor_service).to receive(:call).and_return(Dry::Monads::Success())
      end

      it 'calls the processor service' do
        described_class.perform_now(sales_import.id)

        expect(processor_service).to have_received(:call)
      end

      it 'logs success message' do
        described_class.perform_now(sales_import.id)

        expect(Rails.logger).to have_received(:info)
          .with("Sales import #{sales_import.id} processed successfully")
      end

      it 'does not raise any error' do
        expect {
          described_class.perform_now(sales_import.id)
        }.not_to raise_error
      end
    end

    context 'when processor returns failure' do
      let(:error_message) { 'Invalid data format' }

      before do
        allow(processor_service).to receive(:call).and_return(Dry::Monads::Failure(error_message))
      end

      it 'calls the processor service' do
        expect {
          described_class.perform_now(sales_import.id)
        }.to raise_error(StandardError, error_message)

        expect(processor_service).to have_received(:call)
      end

      it 'logs failure message' do
        expect {
          described_class.perform_now(sales_import.id)
        }.to raise_error(StandardError, error_message)

        expect(Rails.logger).to have_received(:error)
          .with("Sales import #{sales_import.id} failed: #{error_message}")
      end

      it 'raises StandardError with failure message' do
        expect {
          described_class.perform_now(sales_import.id)
        }.to raise_error(StandardError, error_message)
      end
    end

    context 'when processor raises an exception' do
      let(:service_error) { StandardError.new('Database connection failed') }

      before do
        allow(processor_service).to receive(:call).and_raise(service_error)
      end

      it 'logs the exception' do
        expect {
          described_class.perform_now(sales_import.id)
        }.to raise_error(StandardError, 'Database connection failed')

        expect(Rails.logger).to have_received(:error)
          .with("Sales import #{sales_import.id} processing failed: Database connection failed")
      end

      it 'propagates the original exception' do
        expect {
          described_class.perform_now(sales_import.id)
        }.to raise_error(service_error)
      end
    end

    context 'when sales import is not found' do
      it 'logs the error and propagates RecordNotFound' do
        non_existent_id = 999999

        expect {
          described_class.perform_now(non_existent_id)
        }.to raise_error(ActiveRecord::RecordNotFound)

        expect(Rails.logger).to have_received(:error)
          .with("Sales import #{non_existent_id} not found: Couldn't find SalesImport with 'id'=#{non_existent_id}")
      end
    end
  end

  describe 'integration with ActiveJob' do
    context 'when using perform_enqueued_jobs' do
      before do
        allow(processor_service).to receive(:call).and_return(Dry::Monads::Success())
      end

      it 'executes the job asynchronously' do
        perform_enqueued_jobs do
          described_class.perform_later(sales_import.id)
        end

        expect(processor_service).to have_received(:call)
        expect(Rails.logger).to have_received(:info)
          .with("Sales import #{sales_import.id} processed successfully")
      end
    end
  end
end
