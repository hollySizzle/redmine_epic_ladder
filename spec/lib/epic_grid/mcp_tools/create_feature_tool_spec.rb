# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicGrid::McpTools::CreateFeatureTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:epic_tracker) do
    Tracker.create!(name: EpicGrid::TrackerHierarchy.tracker_names[:epic], default_status: IssueStatus.first)
  end
  let(:feature_tracker) do
    Tracker.create!(name: EpicGrid::TrackerHierarchy.tracker_names[:feature], default_status: IssueStatus.first)
  end
  let(:epic) { create(:issue, project: project, tracker: epic_tracker, subject: 'テストEpic') }

  before do
    member
    project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
    project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'creates a Feature successfully' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'CTA',
          parent_epic_id: epic.id.to_s,
          description: 'CTA機能',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['feature_id']).to be_present
        expect(response_text['subject']).to eq('CTA')
        expect(response_text['parent_epic']['id']).to eq(epic.id.to_s)

        feature = Issue.find(response_text['feature_id'])
        expect(feature.tracker.name).to eq(EpicGrid::TrackerHierarchy.tracker_names[:feature])
        expect(feature.parent).to eq(epic)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when parent Epic not found' do
        result = described_class.call(
          project_id: project.identifier,
          subject: 'テストFeature',
          parent_epic_id: '99999',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('親チケットが見つかりません')
      end
    end
  end
end
