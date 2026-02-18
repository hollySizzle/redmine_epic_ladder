# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::UpdateIssueSubjectTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: %i[view_issues edit_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:task_tracker) { find_or_create_task_tracker }
  let(:task) do
    create(:issue,
           project: project,
           tracker: task_tracker,
           subject: 'Original Subject')
  end

  before do
    member
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'updates issue subject successfully' do
        result = described_class.call(
          issue_id: task.id.to_s,
          subject: 'New Subject',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['issue_id']).to eq(task.id.to_s)
        expect(response_text['old_subject']).to eq('Original Subject')
        expect(response_text['new_subject']).to eq('New Subject')

        task.reload
        expect(task.subject).to eq('New Subject')
      end

      it 'updates subject with special characters' do
        result = described_class.call(
          issue_id: task.id.to_s,
          subject: '【重要】タスク名 - v2.0',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        task.reload
        expect(task.subject).to eq('【重要】タスク名 - v2.0')
      end

      it 'updates subject with Japanese text' do
        japanese_subject = 'ログイン機能の実装'
        result = described_class.call(
          issue_id: task.id.to_s,
          subject: japanese_subject,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['new_subject']).to eq(japanese_subject)

        task.reload
        expect(task.subject).to eq(japanese_subject)
      end

      it 'updates subject with HTML-like characters' do
        html_subject = 'Fix <div> & "quote" handling'
        result = described_class.call(
          issue_id: task.id.to_s,
          subject: html_subject,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        task.reload
        expect(task.subject).to eq(html_subject)
      end

      it 'updates subject with emoji characters' do
        emoji_subject = '🚀 Deploy to production'
        result = described_class.call(
          issue_id: task.id.to_s,
          subject: emoji_subject,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        task.reload
        expect(task.subject).to eq(emoji_subject)
      end

      it 'updates subject with maximum length (255 characters)' do
        long_subject = 'A' * 255
        result = described_class.call(
          issue_id: task.id.to_s,
          subject: long_subject,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        task.reload
        expect(task.subject.length).to eq(255)
      end

      it 'returns issue_url in response' do
        result = described_class.call(
          issue_id: task.id.to_s,
          subject: 'URL test subject',
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
          subject: 'New Subject',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケットが見つかりません')
      end

      it 'returns error when subject is blank' do
        result = described_class.call(
          issue_id: task.id.to_s,
          subject: '',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be false
        expect(response_text['error']).to include('件名は必須です')
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
          subject: 'New Subject',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be false
        expect(response_text['error']).to include('権限がありません')
      end
    end
  end
end
