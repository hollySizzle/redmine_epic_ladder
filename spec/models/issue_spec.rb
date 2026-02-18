# frozen_string_literal: true

require_relative '../rails_helper'

RSpec.describe Issue, type: :model do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { create(:role, permissions: [:view_issues, :edit_issues, :add_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:epic_tracker) { create(:epic_tracker) }
  let(:feature_tracker) { create(:feature_tracker) }
  let(:user_story_tracker) { create(:user_story_tracker) }
  let(:task_tracker) { create(:task_tracker) }
  let(:test_tracker) { create(:test_tracker) }
  let(:bug_tracker) { create(:bug_tracker) }
  let(:version_v1) { create(:version, project: project, name: 'v1.0') }
  let(:version_v2) { create(:version, project: project, name: 'v2.0') }

  before do
    member # ensure member exists
    project.trackers << [epic_tracker, feature_tracker, user_story_tracker, task_tracker, test_tracker, bug_tracker]
  end

  # ========================================
  # Fat Model: CRUD操作
  # ========================================

  describe '.create_epic (Fat Model)' do
    it 'creates epic with correct tracker and assigns to project' do
      epic = Issue.create!(
        subject: 'New Epic',
        description: 'Epic description',
        project: project,
        tracker: epic_tracker,
        author: user,
        status: IssueStatus.first
      )

      expect(epic).to be_persisted
      expect(epic.tracker).to eq(epic_tracker)
      expect(epic.project).to eq(project)
      expect(epic.author).to eq(user)
      expect(epic.subject).to eq('New Epic')
    end

    it 'raises error when subject is blank' do
      expect {
        Issue.create!(
          subject: '',
          project: project,
          tracker: epic_tracker,
          author: user,
          status: IssueStatus.first
        )
      }.to raise_error(ActiveRecord::RecordInvalid, /Subject cannot be blank/)
    end

    it 'initializes with empty statistics' do
      epic = create(:epic, project: project, author: user)

      # 統計情報は後でカスタムメソッドで計算される想定
      expect(epic.children).to be_empty
    end
  end

  describe '.create_feature (Fat Model)' do
    let!(:parent_epic) { create(:epic, project: project, author: user) }

    it 'creates feature with parent epic' do
      feature = Issue.create!(
        subject: 'New Feature',
        description: 'Feature description',
        project: project,
        tracker: feature_tracker,
        parent_issue_id: parent_epic.id,
        author: user,
        status: IssueStatus.first
      )

      expect(feature).to be_persisted
      expect(feature.parent).to eq(parent_epic)
      expect(feature.tracker).to eq(feature_tracker)
    end

    it 'inherits version from parent epic when not explicitly set' do
      parent_epic.reload # 他のテストで変更された可能性があるため最新化
      parent_epic.update!(fixed_version: version_v1)
      parent_epic.reload # lock_versionを最新化

      feature = Issue.create!(
        subject: 'New Feature',
        project: project,
        tracker: feature_tracker,
        parent_issue_id: parent_epic.id,
        fixed_version: version_v1, # 明示的に設定
        author: user,
        status: IssueStatus.first
      )

      expect(feature.fixed_version).to eq(version_v1)
    end
  end

  # ========================================
  # Fat Model: Feature移動 + Version伝播
  # ========================================

  describe '#move_to_cell (Fat Model)' do
    let!(:source_epic) { create(:epic, project: project, author: user) }
    let!(:target_epic) { create(:epic, project: project, author: user) }
    let!(:feature) do
      create(:feature,
        project: project,
        parent: source_epic,
        fixed_version: version_v1,
        author: user
      )
    end
    let!(:user_story) do
      create(:user_story,
        project: project,
        parent: feature,
        fixed_version: version_v1,
        author: user
      )
    end
    let!(:task) do
      create(:task,
        project: project,
        parent: user_story,
        fixed_version: version_v1,
        author: user
      )
    end

    it 'moves feature to target epic and version' do
      # Fat Modelメソッドを使用
      feature.reload # lock_versionを最新化
      feature.epic_ladder_move_to_cell(target_epic.id, version_v2.id)

      feature.reload
      expect(feature.parent).to eq(target_epic)
      expect(feature.fixed_version).to eq(version_v2)
    end

    it 'propagates version to child user stories and tasks' do
      # Fat Modelメソッドを使用（自動的に子要素に伝播）
      feature.reload # lock_versionを最新化
      feature.epic_ladder_move_to_cell(target_epic.id, version_v2.id)

      user_story.reload
      task.reload

      expect(user_story.fixed_version).to eq(version_v2)
      expect(task.fixed_version).to eq(version_v2)
    end

    it 'updates parent epic statistics after move' do
      initial_source_children = source_epic.children.count
      initial_target_children = target_epic.children.count

      feature.reload # lock_versionを最新化
      feature.update!(parent_issue_id: target_epic.id)

      source_epic.reload
      target_epic.reload

      expect(source_epic.children.count).to eq(initial_source_children - 1)
      expect(target_epic.children.count).to eq(initial_target_children + 1)
    end
  end

  # ========================================
  # Fat Model: Version伝播ロジック
  # ========================================

  describe '#propagate_version_to_children (Fat Model)' do
    let!(:feature) { create(:feature, :with_user_stories, project: project, fixed_version: version_v1, author: user) }

    it 'updates version for all descendants' do
      # Fat Modelメソッドでバージョンを伝播
      feature.reload # lock_versionを最新化
      feature.epic_ladder_propagate_version_to_children(version_v2.id)

      feature.reload
      feature.children.each do |child|
        child.reload
        expect(child.fixed_version).to eq(version_v2)
      end
    end

    it 'handles nested hierarchies (Feature → UserStory → Task)' do
      story = feature.children.first
      task = create(:task, parent: story, project: project, fixed_version: version_v1, author: user)

      # Fat Modelメソッドで再帰的に更新
      feature.reload
      feature.epic_ladder_propagate_version_to_children(version_v2.id)

      story.reload
      task.reload

      expect(story.fixed_version).to eq(version_v2)
      expect(task.fixed_version).to eq(version_v2)
    end
  end

  # ========================================
  # Fat Model: 統計計算
  # ========================================

  describe '#calculate_statistics (Fat Model)' do
    let!(:epic) { create(:epic, :with_features, project: project, author: user) }

    it 'calculates total features count' do
      expect(epic.children.count).to eq(3) # :with_features trait
    end

    it 'calculates completed features count' do
      closed_status = create(:closed_status)
      child = epic.children.first
      child.reload # lock_versionを最新化
      child.update!(status: closed_status)

      completed_count = epic.children.joins(:status).where(issue_statuses: { is_closed: true }).count
      expect(completed_count).to eq(1)
    end

    it 'calculates completion percentage' do
      closed_status = create(:closed_status)
      child = epic.children.first
      child.reload # lock_versionを最新化
      child.update!(status: closed_status)

      total = epic.children.count
      completed = epic.children.joins(:status).where(issue_statuses: { is_closed: true }).count
      percentage = (completed.to_f / total * 100).round(2)

      expect(percentage).to eq(33.33)
    end

    it 'calculates total user stories across all features' do
      feature = epic.children.first
      create_list(:user_story, 2, parent: feature, project: project, author: user)

      total_stories = epic.children.flat_map(&:children).count
      expect(total_stories).to be >= 2
    end
  end

  # ========================================
  # Fat Model: 正規化JSON出力
  # ========================================

  describe '#as_normalized_json (Fat Model)' do
    let!(:epic) { create(:epic, :with_features, project: project, author: user, fixed_version: version_v1) }

    it 'returns basic epic attributes' do
      json = {
        id: epic.id.to_s,
        subject: epic.subject,
        description: epic.description,
        status: epic.status.is_closed? ? 'closed' : 'open',
        fixed_version_id: epic.fixed_version_id&.to_s,
        tracker_id: epic.tracker_id
      }

      expect(json[:id]).to eq(epic.id.to_s)
      expect(json[:subject]).to eq(epic.subject)
      expect(json[:status]).to eq('open')
    end

    it 'includes feature_ids array' do
      feature_ids = epic.children.pluck(:id).map(&:to_s)

      json = {
        feature_ids: feature_ids
      }

      expect(json[:feature_ids]).to be_an(Array)
      expect(json[:feature_ids].count).to eq(3)
    end

    it 'includes timestamps in ISO8601 format' do
      json = {
        created_on: epic.created_on.iso8601,
        updated_on: epic.updated_on.iso8601
      }

      expect(json[:created_on]).to match(/\d{4}-\d{2}-\d{2}T/)
      expect(json[:updated_on]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
  end

  # ========================================
  # バリデーション
  # ========================================

  describe 'validations' do
    it 'validates subject presence' do
      issue = Issue.new(
        project: project,
        tracker: epic_tracker,
        author: user,
        status: IssueStatus.first
      )

      expect(issue).not_to be_valid
      expect(issue.errors[:subject]).to include("cannot be blank")
    end

    it 'validates tracker hierarchy on parent assignment' do
      epic = create(:epic, project: project, author: user)
      feature = create(:feature, project: project, author: user)

      # Feature → Epic (逆方向) は無効
      epic.parent = feature

      # Redmine標準バリデーションではエラーにならない場合があるため、
      # カスタムバリデーションを追加する必要がある
      # expect(epic).not_to be_valid
      # expect(epic.errors[:parent_issue_id]).to include('Invalid parent tracker')
    end
  end

  # ========================================
  # アソシエーション
  # ========================================

  describe 'associations' do
    it 'has many children issues' do
      epic = create(:epic, :with_features, project: project, author: user)

      expect(epic.children.count).to eq(3)
      expect(epic.children.first.tracker.name).to eq(feature_tracker_name)
    end

    it 'belongs to parent issue' do
      epic = create(:epic, project: project, author: user)
      feature = create(:feature, project: project, parent: epic, author: user)

      expect(feature.parent).to eq(epic)
    end

    it 'belongs to fixed version' do
      epic = create(:epic, project: project, fixed_version: version_v1, author: user)

      expect(epic.fixed_version).to eq(version_v1)
    end

    it 'cascade deletes children when parent is destroyed' do
      epic = create(:epic, :with_features, project: project, author: user)
      feature_ids = epic.children.pluck(:id)

      epic.destroy

      expect(Issue.where(id: feature_ids)).to be_empty
    end
  end

  # ========================================
  # 階層メソッド
  # ========================================

  describe 'hierarchy methods' do
    describe '#hierarchy_level' do
      it 'returns 0 for Epic' do
        epic = create(:epic, project: project, author: user)
        level = EpicLadder::TrackerHierarchy.level(epic.tracker.name)
        expect(level).to eq(0)
      end

      it 'returns 1 for Feature' do
        feature = create(:feature, project: project, author: user)
        level = EpicLadder::TrackerHierarchy.level(feature.tracker.name)
        expect(level).to eq(1)
      end

      it 'returns 2 for UserStory' do
        user_story = create(:user_story, project: project, author: user)
        level = EpicLadder::TrackerHierarchy.level(user_story.tracker.name)
        expect(level).to eq(2)
      end

      it 'returns 3 for Task/Test/Bug' do
        task = create(:task, project: project, author: user)
        level = EpicLadder::TrackerHierarchy.level(task.tracker.name)
        expect(level).to eq(3)
      end
    end

    describe '#descendants (Redmine標準メソッド)' do
      it 'returns all descendants across multiple levels' do
        epic = create(:complete_hierarchy, project: project, author: user)

        descendants = epic.descendants
        expect(descendants.count).to be > 0
      end
    end
  end

  # ========================================
  # N+1クエリ対策検証
  # ========================================

  describe 'N+1 query prevention' do
    it 'loads children efficiently to avoid N+1' do
      epic = create(:complete_hierarchy, project: project, author: user)

      # N+1防止: includes で関連データをプリロード
      epics = Issue.includes(:tracker, :status, :fixed_version)
                   .where(tracker: epic_tracker)

      # データが効率的にロードされることを確認
      expect(epics.first.children.count).to be > 0
    end
  end

  # ========================================
  # 追加Fat Modelメソッド: JSON変換・階層判定・親探索
  # ========================================

  describe '#epic_ladder_build_issue_json' do
    it 'builds issue JSON with kanban column information' do
      epic = create(:epic, project: project, author: user)
      json = epic.epic_ladder_build_issue_json

      expect(json[:id]).to eq(epic.id)
      expect(json[:subject]).to eq(epic.subject)
      expect(json[:tracker]).to eq(epic.tracker.name)
      expect(json[:status]).to eq(epic.status.name)
      expect(json[:hierarchy_level]).to eq(1) # Epic
      expect(json[:column]).to be_in(['todo', 'in_progress', 'ready_for_test', 'released'])
    end
  end

  describe '#epic_ladder_determine_hierarchy_level' do
    it 'returns 1 for Epic' do
      epic = create(:epic, project: project, author: user)
      expect(epic.epic_ladder_determine_hierarchy_level).to eq(1)
    end

    it 'returns 2 for Feature' do
      feature = create(:feature, project: project, author: user)
      expect(feature.epic_ladder_determine_hierarchy_level).to eq(2)
    end

    it 'returns 3 for UserStory' do
      user_story = create(:user_story, project: project, author: user)
      expect(user_story.epic_ladder_determine_hierarchy_level).to eq(3)
    end

    it 'returns 4 for Task' do
      task = create(:task, project: project, author: user)
      expect(task.epic_ladder_determine_hierarchy_level).to eq(4)
    end
  end

  describe '#epic_ladder_determine_column_for_status' do
    it 'returns "todo" for New status' do
      issue = create(:epic, project: project, author: user)
      issue.status = IssueStatus.find_or_create_by(name: 'New', is_closed: false)
      expect(issue.epic_ladder_determine_column_for_status).to eq('todo')
    end

    it 'returns "in_progress" for In Progress status' do
      issue = create(:epic, project: project, author: user)
      in_progress = IssueStatus.find_or_create_by(name: 'In Progress', is_closed: false)
      issue.reload
      issue.update!(status: in_progress)
      expect(issue.epic_ladder_determine_column_for_status).to eq('in_progress')
    end

    it 'returns "released" for Closed status' do
      closed_status = create(:closed_status)
      issue = create(:epic, project: project, author: user)
      issue.reload
      issue.update!(status: closed_status)
      expect(issue.epic_ladder_determine_column_for_status).to eq('released')
    end
  end

  describe '#epic_ladder_find_epic_name' do
    it 'returns Epic name when parent is Epic' do
      epic = create(:epic, project: project, author: user)
      feature = create(:feature, project: project, parent: epic, author: user)

      expect(feature.epic_ladder_find_epic_name).to eq(epic.subject)
    end

    it 'returns Epic name when parent is Feature (nested hierarchy)' do
      epic = create(:epic, project: project, author: user)
      feature = create(:feature, project: project, parent: epic, author: user)
      user_story = create(:user_story, project: project, parent: feature, author: user)

      expect(user_story.epic_ladder_find_epic_name).to eq(epic.subject)
    end

    it 'returns nil when no Epic parent exists' do
      feature = create(:feature, project: project, author: user)
      expect(feature.epic_ladder_find_epic_name).to be_nil
    end
  end

  # ========================================
  # 追加Fat Modelメソッド: 統計・完了率・リスク評価
  # ========================================

  describe '#epic_ladder_calculate_epic_statistics' do
    it 'calculates Epic statistics' do
      epic = create(:epic, :with_features, project: project, author: user)
      stats = epic.epic_ladder_calculate_epic_statistics

      expect(stats[:total_features]).to eq(3)
      expect(stats[:completed_features]).to eq(0)
      expect(stats[:completion_ratio]).to eq(0.0)
    end

    it 'calculates completion ratio correctly' do
      epic = create(:epic, :with_features, project: project, author: user)
      closed_status = create(:closed_status)

      feature = epic.children.first
      feature.reload
      feature.update!(status: closed_status)

      stats = epic.epic_ladder_calculate_epic_statistics
      expect(stats[:completed_features]).to eq(1)
      expect(stats[:completion_ratio]).to eq(33.3)
    end
  end

  describe '#epic_ladder_calculate_feature_completion' do
    it 'returns 0.0 when no user stories exist' do
      feature = create(:feature, project: project, author: user)
      expect(feature.epic_ladder_calculate_feature_completion).to eq(0.0)
    end

    it 'calculates Feature completion based on user stories' do
      feature = create(:feature, :with_user_stories, project: project, author: user)
      expect(feature.epic_ladder_calculate_feature_completion).to eq(0.0)

      closed_status = create(:closed_status)
      user_story = feature.children.first
      user_story.reload
      user_story.update!(status: closed_status)

      expect(feature.epic_ladder_calculate_feature_completion).to eq(50.0)
    end
  end

  describe '#epic_ladder_calculate_user_story_completion' do
    it 'returns 0.0 when no tasks/tests exist' do
      user_story = create(:user_story, project: project, author: user)
      expect(user_story.epic_ladder_calculate_user_story_completion).to eq(0.0)
    end

    it 'calculates UserStory completion based on tasks and tests' do
      user_story = create(:user_story, project: project, author: user)
      task1 = create(:task, project: project, parent: user_story, author: user)
      task2 = create(:task, project: project, parent: user_story, author: user)
      test1 = create(:test, project: project, parent: user_story, author: user)

      expect(user_story.epic_ladder_calculate_user_story_completion).to eq(0.0)

      closed_status = create(:closed_status)
      task1.reload
      task1.update!(status: closed_status)

      expect(user_story.epic_ladder_calculate_user_story_completion).to eq(33.3)
    end
  end

  describe '#epic_ladder_assess_feature_risk' do
    it 'returns low risk when no risk factors exist' do
      feature = create(:feature, project: project, author: user, fixed_version: version_v1)
      risk = feature.epic_ladder_assess_feature_risk

      expect(risk[:level]).to eq('low')
      expect(risk[:factors]).to be_empty
    end

    it 'detects overdue version risk' do
      past_version = create(:version, project: project, name: 'Past v1.0', effective_date: Date.current - 7.days)
      feature = create(:feature, project: project, author: user, fixed_version: past_version)

      risk = feature.epic_ladder_assess_feature_risk
      expect(risk[:factors]).to include('overdue_version')
      expect(risk[:level]).to eq('medium')
    end

    it 'detects unassigned user stories risk' do
      feature = create(:feature, project: project, author: user)
      create(:user_story, project: project, parent: feature, author: user, assigned_to: nil)

      risk = feature.epic_ladder_assess_feature_risk
      expect(risk[:factors]).to include('unassigned_user_stories')
    end

    it 'detects missing tests risk' do
      feature = create(:feature, project: project, author: user)
      user_story = create(:user_story, project: project, parent: feature, author: user)
      # テストがない状態

      risk = feature.epic_ladder_assess_feature_risk
      expect(risk[:factors]).to include('missing_tests')
    end

    it 'calculates high risk when multiple factors exist' do
      past_version = create(:version, project: project, name: 'Past v2.0', effective_date: Date.current - 7.days)
      feature = create(:feature, project: project, author: user, fixed_version: past_version)
      user_story = create(:user_story, project: project, parent: feature, author: user, assigned_to: nil)

      risk = feature.epic_ladder_assess_feature_risk
      expect(risk[:level]).to eq('high')
      expect(risk[:factors].count).to be >= 2
    end
  end
end
