# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::AddIssueCommentTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues, :add_issue_notes]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:task_tracker) do
    Tracker.create!(
      name: EpicLadder::TrackerHierarchy.tracker_names[:task],
      default_status: IssueStatus.first
    )
  end
  let(:task) { create(:issue, project: project, tracker: task_tracker, subject: 'Test Task') }

  before do
    member # ensure member exists
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'adds comment to issue successfully' do
        result = described_class.call(
          issue_id: task.id.to_s,
          comment: '実装完了、レビュー待ち',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['issue_id']).to eq(task.id.to_s)
        expect(response_text['comment']).to eq('実装完了、レビュー待ち')
        expect(response_text['journal_id']).to be_present

        # コメントが実際に追加されたか確認
        task.reload
        latest_journal = task.journals.order(created_on: :desc).first
        expect(latest_journal.notes).to eq('実装完了、レビュー待ち')
        expect(latest_journal.user).to eq(user)
      end

      it 'adds multiple comments to the same issue' do
        described_class.call(
          issue_id: task.id.to_s,
          comment: '最初のコメント',
          server_context: server_context
        )

        result = described_class.call(
          issue_id: task.id.to_s,
          comment: '2番目のコメント',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be true

        # 複数のコメントが保存されているか確認
        task.reload
        expect(task.journals.count).to be >= 2
      end

      it 'adds comment with Markdown formatting' do
        markdown_comment = "## 進捗報告\n\n- タスク1: 完了\n- タスク2: 進行中\n\n**重要**: 締切注意"
        result = described_class.call(
          issue_id: task.id.to_s,
          comment: markdown_comment,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        task.reload
        latest_journal = task.journals.order(created_on: :desc).first
        expect(latest_journal.notes).to include('## 進捗報告')
        expect(latest_journal.notes).to include('**重要**')
      end

      it 'adds comment with special characters' do
        special_comment = 'Fix: <div> & "quote" issues (R) (c) © ™'
        result = described_class.call(
          issue_id: task.id.to_s,
          comment: special_comment,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        task.reload
        latest_journal = task.journals.order(created_on: :desc).first
        expect(latest_journal.notes).to eq(special_comment)
      end

      it 'adds comment with emoji characters' do
        emoji_comment = '✅ 完了 🎉 素晴らしい！ 🚀 デプロイ準備OK'
        result = described_class.call(
          issue_id: task.id.to_s,
          comment: emoji_comment,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        task.reload
        latest_journal = task.journals.order(created_on: :desc).first
        expect(latest_journal.notes).to eq(emoji_comment)
      end

      it 'adds very long comment (over 5000 characters)' do
        long_comment = 'A' * 5500
        result = described_class.call(
          issue_id: task.id.to_s,
          comment: long_comment,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        task.reload
        latest_journal = task.journals.order(created_on: :desc).first
        expect(latest_journal.notes.length).to eq(5500)
      end

      it 'returns issue_url in response' do
        result = described_class.call(
          issue_id: task.id.to_s,
          comment: 'URL確認用コメント',
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
          comment: 'テストコメント',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケットが見つかりません')
      end

      it 'returns error when user lacks permission' do
        unauthorized_user = create(:user)
        unauthorized_context = { user: unauthorized_user }

        result = described_class.call(
          issue_id: task.id.to_s,
          comment: 'テストコメント',
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('コメント追加権限がありません')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('comment')
      expect(described_class.description).to include('issue')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:issue_id, :comment)
      expect(schema.instance_variable_get(:@required)).to include(:issue_id, :comment)
    end
  end
end
