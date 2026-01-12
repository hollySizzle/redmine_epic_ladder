# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::GetIssueDetailTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: [:view_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:user_story_tracker) { find_or_create_user_story_tracker }
  let(:task_tracker) { find_or_create_task_tracker }
  let(:version) { create(:version, project: project, name: 'Version 1.0') }
  let(:priority) { IssuePriority.first }

  before do
    member # ensure member exists
    project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid issue' do
      let(:user_story) do
        create(:issue,
               project: project,
               tracker: user_story_tracker,
               subject: 'Test UserStory',
               description: 'This is a test user story',
               author: user,
               assigned_to: user,
               fixed_version: version,
               priority: priority,
               estimated_hours: 8.0,
               done_ratio: 50)
      end

      it 'returns issue details successfully' do
        result = described_class.call(
          issue_id: user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        # Issue本体の検証
        issue_data = response_text['issue']
        expect(issue_data['id']).to eq(user_story.id.to_s)
        expect(issue_data['subject']).to eq('Test UserStory')
        expect(issue_data['description']).to eq('This is a test user story')

        # Tracker情報
        expect(issue_data['tracker']['id']).to eq(user_story_tracker.id.to_s)
        expect(issue_data['tracker']['name']).to eq(user_story_tracker.name)

        # Status情報
        expect(issue_data['status']['id']).to be_present
        expect(issue_data['status']['name']).to be_present
        expect(issue_data['status']['is_closed']).to be_in([true, false])

        # Priority情報
        expect(issue_data['priority']['id']).to eq(priority.id.to_s)
        expect(issue_data['priority']['name']).to eq(priority.name)

        # Author情報
        expect(issue_data['author']['id']).to eq(user.id.to_s)
        expect(issue_data['author']['name']).to be_present

        # Assigned To情報
        expect(issue_data['assigned_to']['id']).to eq(user.id.to_s)
        expect(issue_data['assigned_to']['name']).to be_present

        # Version情報
        expect(issue_data['fixed_version']['id']).to eq(version.id.to_s)
        expect(issue_data['fixed_version']['name']).to eq('Version 1.0')

        # その他のフィールド
        expect(issue_data['estimated_hours']).to eq(8.0)
        expect(issue_data['done_ratio']).to eq(50)
        expect(issue_data['url']).to include("/issues/#{user_story.id}")

        # Journals（コメント）の検証
        expect(response_text['journals']).to be_an(Array)
        expect(response_text['journals_count']).to be >= 0

        # Children（子チケット）の検証
        expect(response_text['children']).to be_an(Array)
        expect(response_text['children_count']).to eq(0)
      end

      it 'returns issue with comments (journals)' do
        # テスト用Issueを新規作成
        test_issue = create(:issue,
                            project: project,
                            tracker: user_story_tracker,
                            subject: 'Issue with comments',
                            author: user)

        # コメント追加（Journalを直接作成する方法に変更）
        Journal.create!(
          journalized: test_issue,
          user: user,
          notes: 'First comment'
        )

        Journal.create!(
          journalized: test_issue,
          user: user,
          notes: 'Second comment'
        )

        result = described_class.call(
          issue_id: test_issue.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        # Journals検証
        journals = response_text['journals']
        expect(journals).to be_an(Array)
        expect(response_text['journals_count']).to eq(2)

        # 最初のJournal
        first_journal = journals.first
        expect(first_journal['id']).to be_present
        expect(first_journal['notes']).to eq('First comment')
        expect(first_journal['user']['id']).to eq(user.id.to_s)
        expect(first_journal['user']['name']).to be_present
        expect(first_journal['created_on']).to be_present
        expect(first_journal['details']).to be_an(Array)
      end

      it 'returns issue with children' do
        # 子チケット作成
        child1 = create(:issue,
                        project: project,
                        tracker: task_tracker,
                        parent_issue_id: user_story.id,
                        subject: 'Child Task 1')

        child2 = create(:issue,
                        project: project,
                        tracker: task_tracker,
                        parent_issue_id: user_story.id,
                        subject: 'Child Task 2')

        result = described_class.call(
          issue_id: user_story.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        # Children検証
        children = response_text['children']
        expect(children).to be_an(Array)
        expect(response_text['children_count']).to eq(2)

        # 子チケットの情報
        child_ids = children.map { |c| c['id'] }
        expect(child_ids).to include(child1.id.to_s, child2.id.to_s)

        first_child = children.first
        expect(first_child['subject']).to be_present
        expect(first_child['tracker']).to be_present
        expect(first_child['status']).to be_present
      end

      it 'returns issue with parent information' do
        # 親チケット作成
        parent = create(:issue,
                        project: project,
                        tracker: user_story_tracker,
                        subject: 'Parent Issue')

        child = create(:issue,
                       project: project,
                       tracker: task_tracker,
                       parent_issue_id: parent.id,
                       subject: 'Child Issue')

        result = described_class.call(
          issue_id: child.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        # Parent情報検証
        issue_data = response_text['issue']
        expect(issue_data['parent']).to be_present
        expect(issue_data['parent']['id']).to eq(parent.id.to_s)
        expect(issue_data['parent']['subject']).to eq('Parent Issue')
      end
    end

    context 'with invalid parameters' do
      it 'returns error when issue not found' do
        result = described_class.call(
          issue_id: '99999',
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケットが見つかりません')
      end

      it 'returns error when user lacks permission' do
        unauthorized_user = create(:user)
        unauthorized_context = { user: unauthorized_user }

        user_story = create(:issue, project: project, tracker: user_story_tracker)

        result = described_class.call(
          issue_id: user_story.id.to_s,
          server_context: unauthorized_context
        )

        response_text = JSON.parse(result.content.first[:text])
        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケット閲覧権限がありません')
      end
    end

    context 'with optional fields' do
      it 'returns issue without assigned_to' do
        issue_without_assignee = create(:issue,
                                        project: project,
                                        tracker: user_story_tracker,
                                        subject: 'No Assignee Issue',
                                        author: user,
                                        assigned_to: nil)

        result = described_class.call(
          issue_id: issue_without_assignee.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['issue']['assigned_to']).to be_nil
      end

      it 'returns issue without version' do
        issue_without_version = create(:issue,
                                       project: project,
                                       tracker: user_story_tracker,
                                       subject: 'No Version Issue',
                                       author: user,
                                       fixed_version: nil)

        result = described_class.call(
          issue_id: issue_without_version.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['issue']['fixed_version']).to be_nil
      end

      it 'returns issue with start_date and due_date' do
        issue_with_dates = create(:issue,
                                  project: project,
                                  tracker: user_story_tracker,
                                  subject: 'Issue with dates',
                                  author: user,
                                  start_date: Date.today,
                                  due_date: Date.today + 14)

        result = described_class.call(
          issue_id: issue_with_dates.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['issue']['start_date']).to eq(Date.today.to_s)
        expect(response_text['issue']['due_date']).to eq((Date.today + 14).to_s)
      end

      it 'returns empty journals when no comments' do
        issue_without_journals = create(:issue,
                                        project: project,
                                        tracker: user_story_tracker,
                                        subject: 'No Comments Issue',
                                        author: user)

        result = described_class.call(
          issue_id: issue_without_journals.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['journals']).to eq([])
        expect(response_text['journals_count']).to eq(0)
      end
    end

    context 'journal details' do
      it 'returns journal with field change details' do
        # チケット作成
        test_issue = create(:issue,
                            project: project,
                            tracker: user_story_tracker,
                            subject: 'Original Subject',
                            author: user,
                            status: IssueStatus.first)

        # ステータス変更などの履歴を持つJournalを作成
        journal = Journal.create!(
          journalized: test_issue,
          user: user,
          notes: 'Changed status'
        )

        # JournalDetailを追加（ステータス変更）
        JournalDetail.create!(
          journal: journal,
          property: 'attr',
          prop_key: 'status_id',
          old_value: '1',
          value: '2'
        )

        result = described_class.call(
          issue_id: test_issue.id.to_s,
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        journal_data = response_text['journals'].first
        expect(journal_data['details']).to be_an(Array)
        expect(journal_data['details'].first['property']).to eq('attr')
        expect(journal_data['details'].first['name']).to eq('status_id')
      end
    end
  end

  describe 'tool metadata' do
    it 'has correct description' do
      expect(described_class.description).to include('issue')
      expect(described_class.description).to include('details')
    end

    it 'has required input schema' do
      schema = described_class.input_schema
      expect(schema.properties).to include(:issue_id)
      expect(schema.instance_variable_get(:@required)).to include(:issue_id)
    end
  end
end
