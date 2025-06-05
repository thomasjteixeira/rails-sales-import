require 'rails_helper'

RSpec.describe DashboardHelper, type: :helper do
   describe '#status_badge_class' do
    it 'returns correct badge classes for known statuses' do
      status_mappings = {
        'completed' => 'badge-success',
        :completed => 'badge-success',
        'processing' => 'badge-info',
        :processing => 'badge-info',
        'failed' => 'badge-error',
        :failed => 'badge-error',
        'pending' => 'badge-warning',
        :pending => 'badge-warning'
      }

      status_mappings.each do |status, expected_class|
        expect(helper.status_badge_class(status)).to eq(expected_class)
      end
    end

    it 'returns badge-neutral for unknown or invalid statuses' do
      [ 'unknown', '', nil, :invalid ].each do |status|
        expect(helper.status_badge_class(status)).to eq('badge-neutral')
      end
    end
  end

  describe 'integration with view rendering' do
    it 'can be used in view context' do
      status = 'completed'
      badge_class = helper.status_badge_class(status)

      html = "<span class=\"badge #{badge_class}\">#{status.humanize}</span>"
      expect(html).to include('badge-success')
      expect(html).to include('Completed')
    end
  end
end
