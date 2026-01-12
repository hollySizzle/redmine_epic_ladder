# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::UpdateIssueDescriptionTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: %i[view_issues edit_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:task_tracker) do
    Tracker.create!(
      name: EpicLadder::TrackerHierarchy.tracker_names[:task],
      default_status: IssueStatus.first
    )
  end
  let(:task) do
    create(:issue,
           project: project,
           tracker: task_tracker,
           description: 'Original description')
  end

  before do
    member
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'updates issue description successfully' do
        result = described_class.call(
          issue_id: task.id.to_s,
          description: 'New description',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['issue_id']).to eq(task.id.to_s)
        expect(response_text['old_description']).to eq('Original description')
        expect(response_text['new_description']).to eq('New description')

        task.reload
        expect(task.description).to eq('New description')
      end

      it 'updates description to empty string' do
        result = described_class.call(
          issue_id: task.id.to_s,
          description: '',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        task.reload
        expect(task.description).to eq('')
      end

      it 'updates description with multiline text' do
        multiline_description = "Line 1\nLine 2\nLine 3"
        result = described_class.call(
          issue_id: task.id.to_s,
          description: multiline_description,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['new_description']).to eq(multiline_description)

        task.reload
        # Redmineは改行コードを正規化する場合があるため、内容のみ確認
        expect(task.description.gsub("\r\n", "\n")).to eq(multiline_description)
      end

      it 'updates description with Japanese text' do
        japanese_description = 'これは日本語の説明文です。テスト用の文章。'
        result = described_class.call(
          issue_id: task.id.to_s,
          description: japanese_description,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['new_description']).to eq(japanese_description)

        task.reload
        expect(task.description).to eq(japanese_description)
      end

      it 'updates description with Markdown formatting' do
        markdown_description = "# Heading\n\n- item1\n- item2\n\n**bold**"
        result = described_class.call(
          issue_id: task.id.to_s,
          description: markdown_description,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        task.reload
        expect(task.description).to include('# Heading')
        expect(task.description).to include('**bold**')
      end

      it 'updates description with special characters' do
        special_description = 'Chars: <html> & "quotes" (c) (R)'
        result = described_class.call(
          issue_id: task.id.to_s,
          description: special_description,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        task.reload
        expect(task.description).to eq(special_description)
      end

      it 'updates description with long text (over 10000 characters)' do
        long_description = 'A' * 15000
        result = described_class.call(
          issue_id: task.id.to_s,
          description: long_description,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        task.reload
        expect(task.description.length).to eq(15000)
      end

      it 'returns issue_url in response' do
        result = described_class.call(
          issue_id: task.id.to_s,
          description: 'URL test',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['issue_url']).to be_present
      end
    end

    context 'with invalid parameters' do
      it 'returns error when issue not found' do
        result = described_class.call(
          issue_id: '99999',
          description: 'New description',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケットが見つかりません')
      end
    end

    context 'without permission' do
      let(:role_without_permission) { create(:role, permissions: [:view_issues]) }
      let(:member_without_permission) do
        create(:member, project: project, user: user, roles: [role_without_permission])
      end

      before do
        member.destroy
        member_without_permission
      end

      it 'returns permission error' do
        result = described_class.call(
          issue_id: task.id.to_s,
          description: 'New description',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be false
        expect(response_text['error']).to include('権限がありません')
      end
    end
  end
end
