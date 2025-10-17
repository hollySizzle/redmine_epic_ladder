# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicGrid::GridController, type: :controller do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { create(:role, :with_kanban_permissions) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }

  before do
    member # ensure member exists
    allow(User).to receive(:current).and_return(user)
    @request.session[:user_id] = user.id
  end

  describe 'GET #show' do
    it 'returns successful response' do
      get :show, params: { project_id: project.id }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
    end

    it 'returns normalized API response structure (MSW準拠)' do
      get :show, params: { project_id: project.id }

      json = JSON.parse(response.body)

      # MSW準拠: トップレベルに直接データ構造（success/dataラッパーなし）
      expect(json).to have_key('entities')
      expect(json).to have_key('grid')
      expect(json).to have_key('metadata')
      expect(json).to have_key('statistics')
    end

    it 'includes all entity types in response' do
      get :show, params: { project_id: project.id }

      json = JSON.parse(response.body)

      expect(json['entities']).to include(
        'epics',
        'versions',
        'features',
        'user_stories',
        'tasks',
        'tests',
        'bugs',
        'users'
      )
    end

    it 'includes project metadata' do
      get :show, params: { project_id: project.id }

      json = JSON.parse(response.body)

      expect(json['metadata']['project']).to include(
        'id' => project.id,
        'name' => project.name,
        'identifier' => project.identifier
      )
    end

    it 'includes available_statuses in metadata for filtering' do
      get :show, params: { project_id: project.id }

      json = JSON.parse(response.body)

      expect(json['metadata']).to have_key('available_statuses')
      expect(json['metadata']['available_statuses']).to be_an(Array)

      # 少なくとも1つのステータスがあること
      expect(json['metadata']['available_statuses'].length).to be > 0

      # 各ステータスが正しい構造を持つこと
      first_status = json['metadata']['available_statuses'].first
      expect(first_status).to include(
        'id',
        'name',
        'is_closed'
      )
      expect(first_status['id']).to be_a(Integer)
      expect(first_status['name']).to be_a(String)
      expect([true, false]).to include(first_status['is_closed'])
    end

    it 'includes available_trackers in metadata for filtering' do
      get :show, params: { project_id: project.id }

      json = JSON.parse(response.body)

      expect(json['metadata']).to have_key('available_trackers')
      expect(json['metadata']['available_trackers']).to be_an(Array)

      # プロジェクトに割り当てられたトラッカーのみが含まれること
      # （新規プロジェクトの場合は0個の可能性もある）
      expect(json['metadata']['available_trackers']).to be_an(Array)

      # トラッカーがある場合、正しい構造を持つこと
      if json['metadata']['available_trackers'].any?
        first_tracker = json['metadata']['available_trackers'].first
        expect(first_tracker).to include(
          'id',
          'name'
        )
        expect(first_tracker['id']).to be_a(Integer)
        expect(first_tracker['name']).to be_a(String)
        # description は optional なので存在チェックのみ
        expect(first_tracker.keys).to include('description')
      end
    end

    context 'when filtering by status_id_in' do
      let!(:epic_tracker) { create(:epic_tracker) }
      let!(:status_new) { IssueStatus.where(is_closed: false).first }
      let!(:status_in_progress) { IssueStatus.where(is_closed: false).offset(1).first }

      before do
        project.trackers << epic_tracker

        # 異なるステータスが存在することを確認
        unless status_new && status_in_progress && status_new.id != status_in_progress.id
          skip 'Need at least 2 different open statuses'
        end
      end

      let!(:epic_with_status_new) do
        create(:epic, project: project, author: user, status_id: status_new.id)
      end

      let!(:epic_with_status_in_progress) do
        create(:epic, project: project, author: user, status_id: status_in_progress.id)
      end

      it 'filters epics by status_id_in parameter' do
        get :show, params: {
          project_id: project.id,
          filters: { status_id_in: [status_new.id] }
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        epic_ids = json['entities']['epics'].keys

        # status_newのEpicのみが返されること
        expect(epic_ids).to include(epic_with_status_new.id.to_s)
        expect(epic_ids).not_to include(epic_with_status_in_progress.id.to_s)
      end

      it 'filters epics by multiple status_id_in values' do
        get :show, params: {
          project_id: project.id,
          filters: { status_id_in: [status_new.id, status_in_progress.id] }
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        epic_ids = json['entities']['epics'].keys

        # 両方のEpicが返されること
        expect(epic_ids).to include(epic_with_status_new.id.to_s)
        expect(epic_ids).to include(epic_with_status_in_progress.id.to_s)
      end
    end

    context 'when filtering by tracker_id_in' do
      let!(:epic_tracker) { create(:epic_tracker) }
      let!(:feature_tracker) { create(:feature_tracker) }

      before do
        project.trackers << [epic_tracker, feature_tracker]
      end

      let!(:epic) { create(:epic, project: project, author: user) }
      let!(:feature) { create(:feature, project: project, parent: epic, author: user) }

      it 'filters issues by tracker_id_in parameter' do
        get :show, params: {
          project_id: project.id,
          filters: { tracker_id_in: [epic_tracker.id] }
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)

        # Epic trackerのIssueのみが返されること
        epic_ids = json['entities']['epics'].keys
        feature_ids = json['entities']['features'].keys

        expect(epic_ids).to include(epic.id.to_s)
        # Featureはepic_trackerではないのでフィルタされる
        expect(feature_ids).not_to include(feature.id.to_s)
      end
    end

    context 'when filtering by fixed_version_effective_date (Ransack association search)' do
      let!(:epic_tracker) { create(:epic_tracker) }
      let!(:feature_tracker) { create(:feature_tracker) }

      before do
        project.trackers << [epic_tracker, feature_tracker]
      end

      # バージョン期日が 2025-01-15, 2025-02-15, 2025-03-15 のバージョンを作成
      let!(:version_jan) { create(:version, project: project, name: 'January Release', effective_date: '2025-01-15') }
      let!(:version_feb) { create(:version, project: project, name: 'February Release', effective_date: '2025-02-15') }
      let!(:version_mar) { create(:version, project: project, name: 'March Release', effective_date: '2025-03-15') }
      let!(:version_no_date) { create(:version, project: project, name: 'No Date Version', effective_date: nil) }

      # 各バージョンに紐づくEpicとFeatureを作成
      let!(:epic_jan) { create(:epic, project: project, author: user, subject: 'Epic Jan', fixed_version: version_jan) }
      let!(:feature_jan) { create(:feature, project: project, parent: epic_jan, author: user, subject: 'Feature Jan', fixed_version: version_jan) }

      let!(:epic_feb) { create(:epic, project: project, author: user, subject: 'Epic Feb', fixed_version: version_feb) }
      let!(:feature_feb) { create(:feature, project: project, parent: epic_feb, author: user, subject: 'Feature Feb', fixed_version: version_feb) }

      let!(:epic_mar) { create(:epic, project: project, author: user, subject: 'Epic Mar', fixed_version: version_mar) }
      let!(:feature_mar) { create(:feature, project: project, parent: epic_mar, author: user, subject: 'Feature Mar', fixed_version: version_mar) }

      let!(:epic_no_version) { create(:epic, project: project, author: user, subject: 'Epic No Version', fixed_version: nil) }
      let!(:epic_no_date) { create(:epic, project: project, author: user, subject: 'Epic No Date', fixed_version: version_no_date) }

      it 'filters issues by fixed_version_effective_date_gteq (期日が指定日以降)' do
        get :show, params: {
          project_id: project.id,
          filters: { fixed_version_effective_date_gteq: '2025-02-01' }
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        epic_ids = json['entities']['epics'].keys
        feature_ids = json['entities']['features'].keys
        version_ids = json['entities']['versions'].keys

        # Epic/Featureは全て表示される（Versionフィルタの影響を受けない）
        expect(epic_ids).to include(epic_jan.id.to_s)
        expect(epic_ids).to include(epic_feb.id.to_s)
        expect(epic_ids).to include(epic_mar.id.to_s)
        expect(epic_ids).to include(epic_no_version.id.to_s)
        expect(epic_ids).to include(epic_no_date.id.to_s)

        expect(feature_ids).to include(feature_jan.id.to_s)
        expect(feature_ids).to include(feature_feb.id.to_s)
        expect(feature_ids).to include(feature_mar.id.to_s)

        # Versionは期日でフィルタされること（2月、3月のみ）
        expect(version_ids).to include(version_feb.id.to_s)
        expect(version_ids).to include(version_mar.id.to_s)
        expect(version_ids).not_to include(version_jan.id.to_s)
        expect(version_ids).not_to include(version_no_date.id.to_s)
      end

      it 'filters issues by fixed_version_effective_date_lteq (期日が指定日以前)' do
        get :show, params: {
          project_id: project.id,
          filters: { fixed_version_effective_date_lteq: '2025-02-20' }
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        epic_ids = json['entities']['epics'].keys
        feature_ids = json['entities']['features'].keys
        version_ids = json['entities']['versions'].keys

        # Epic/Featureは全て表示される（Versionフィルタの影響を受けない）
        expect(epic_ids).to include(epic_jan.id.to_s)
        expect(epic_ids).to include(epic_feb.id.to_s)
        expect(epic_ids).to include(epic_mar.id.to_s)
        expect(epic_ids).to include(epic_no_version.id.to_s)
        expect(epic_ids).to include(epic_no_date.id.to_s)

        expect(feature_ids).to include(feature_jan.id.to_s)
        expect(feature_ids).to include(feature_feb.id.to_s)
        expect(feature_ids).to include(feature_mar.id.to_s)

        # Versionは期日でフィルタされること（1月、2月のみ）
        expect(version_ids).to include(version_jan.id.to_s)
        expect(version_ids).to include(version_feb.id.to_s)
        expect(version_ids).not_to include(version_mar.id.to_s)
        expect(version_ids).not_to include(version_no_date.id.to_s)
      end

      it 'filters issues by date range (gteq and lteq combined)' do
        get :show, params: {
          project_id: project.id,
          filters: {
            fixed_version_effective_date_gteq: '2025-01-20',
            fixed_version_effective_date_lteq: '2025-02-28'
          }
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        epic_ids = json['entities']['epics'].keys
        feature_ids = json['entities']['features'].keys
        version_ids = json['entities']['versions'].keys

        # Epic/Featureは全て表示される（Versionフィルタの影響を受けない）
        expect(epic_ids).to include(epic_jan.id.to_s)
        expect(epic_ids).to include(epic_feb.id.to_s)
        expect(epic_ids).to include(epic_mar.id.to_s)
        expect(epic_ids).to include(epic_no_version.id.to_s)
        expect(epic_ids).to include(epic_no_date.id.to_s)

        expect(feature_ids).to include(feature_jan.id.to_s)
        expect(feature_ids).to include(feature_feb.id.to_s)
        expect(feature_ids).to include(feature_mar.id.to_s)

        # Versionは期日範囲でフィルタされること（2月のみ）
        expect(version_ids).to include(version_feb.id.to_s)
        expect(version_ids).not_to include(version_jan.id.to_s)
        expect(version_ids).not_to include(version_mar.id.to_s)
        expect(version_ids).not_to include(version_no_date.id.to_s)
      end

      it 'excludes versions without effective_date when date filter is active' do
        get :show, params: {
          project_id: project.id,
          filters: { fixed_version_effective_date_gteq: '2025-01-01' }
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        epic_ids = json['entities']['epics'].keys
        version_ids = json['entities']['versions'].keys

        # Epic/Featureは全て表示される（Versionなしも含む）
        expect(epic_ids).to include(epic_no_version.id.to_s)
        expect(epic_ids).to include(epic_jan.id.to_s)
        expect(epic_ids).to include(epic_feb.id.to_s)
        expect(epic_ids).to include(epic_mar.id.to_s)

        # 期日なしバージョンは除外されること
        expect(version_ids).not_to include(version_no_date.id.to_s)

        # 期日ありバージョンは含まれること
        expect(version_ids).to include(version_jan.id.to_s)
        expect(version_ids).to include(version_feb.id.to_s)
        expect(version_ids).to include(version_mar.id.to_s)
      end

      it 'epics are always displayed regardless of version filter' do
        get :show, params: {
          project_id: project.id,
          filters: { fixed_version_effective_date_gteq: '2025-02-01' }
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        epic_ids = json['entities']['epics'].keys

        # 全てのEpicが表示されること（Versionフィルタに関係なく）
        expect(epic_ids).to include(epic_jan.id.to_s)
        expect(epic_ids).to include(epic_feb.id.to_s)
        expect(epic_ids).to include(epic_mar.id.to_s)
        expect(epic_ids).to include(epic_no_version.id.to_s)
        expect(epic_ids).to include(epic_no_date.id.to_s)
      end
    end

    context 'when filtering by parent_id_in (Epic filter)' do
      let!(:epic_tracker) { create(:epic_tracker) }
      let!(:feature_tracker) { create(:feature_tracker) }

      before do
        project.trackers << [epic_tracker, feature_tracker]
      end

      let!(:epic1) { create(:epic, project: project, author: user, subject: 'Epic 1') }
      let!(:epic2) { create(:epic, project: project, author: user, subject: 'Epic 2') }
      let!(:feature1) { create(:feature, project: project, parent: epic1, author: user, subject: 'Feature 1') }
      let!(:feature2) { create(:feature, project: project, parent: epic2, author: user, subject: 'Feature 2') }

      it 'filters features by parent_id_in parameter' do
        get :show, params: {
          project_id: project.id,
          filters: { parent_id_in: [epic1.id] }
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        epic_ids = json['entities']['epics'].keys
        feature_ids = json['entities']['features'].keys

        # epic1自身も返されること（階層検索）
        expect(epic_ids).to include(epic1.id.to_s)
        # epic1配下のfeature1のみが返されること
        expect(feature_ids).to include(feature1.id.to_s)
        expect(feature_ids).not_to include(feature2.id.to_s)
      end

      it 'filters features by multiple parent_id_in values' do
        get :show, params: {
          project_id: project.id,
          filters: { parent_id_in: [epic1.id, epic2.id] }
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        feature_ids = json['entities']['features'].keys

        # 両方のFeatureが返されること
        expect(feature_ids).to include(feature1.id.to_s)
        expect(feature_ids).to include(feature2.id.to_s)
      end

      it 'returns the parent epic itself along with its descendants (hierarchical search)' do
        get :show, params: {
          project_id: project.id,
          filters: { parent_id_in: [epic1.id] }
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        epic_ids = json['entities']['epics'].keys
        feature_ids = json['entities']['features'].keys

        # Epic自身も返されること（階層検索）
        expect(epic_ids).to include(epic1.id.to_s)
        # Epic配下のFeatureも返されること
        expect(feature_ids).to include(feature1.id.to_s)
        # 別のEpicとそのFeatureは返されないこと
        expect(epic_ids).not_to include(epic2.id.to_s)
        expect(feature_ids).not_to include(feature2.id.to_s)
      end

      it 'returns ancestors when filtering by feature (Feature → Epic)' do
        get :show, params: {
          project_id: project.id,
          filters: { parent_id_in: [feature1.id] }
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        epic_ids = json['entities']['epics'].keys
        feature_ids = json['entities']['features'].keys

        # Feature自身も返されること
        expect(feature_ids).to include(feature1.id.to_s)
        # 親Epicも返されること（祖先の取得）
        expect(epic_ids).to include(epic1.id.to_s)
        # 別のEpicとFeatureは返されないこと
        expect(epic_ids).not_to include(epic2.id.to_s)
        expect(feature_ids).not_to include(feature2.id.to_s)
      end

      context 'with deeper hierarchy (Epic → Feature → UserStory → Task)' do
        let!(:user_story_tracker) { create(:user_story_tracker) }
        let!(:task_tracker) { create(:task_tracker) }

        before do
          project.trackers << [user_story_tracker, task_tracker]
        end

        let!(:user_story1) { create(:user_story, project: project, parent: feature1, author: user, subject: 'US 1') }
        let!(:task1) { create(:task, project: project, parent: user_story1, author: user, subject: 'Task 1') }

        it 'returns all ancestors and descendants when filtering by UserStory' do
          get :show, params: {
            project_id: project.id,
            filters: { parent_id_in: [user_story1.id] }
          }

          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)
          epic_ids = json['entities']['epics'].keys
          feature_ids = json['entities']['features'].keys
          user_story_ids = json['entities']['user_stories'].keys
          task_ids = json['entities']['tasks'].keys

          # 祖父Epic、親Feature、UserStory自身、子Taskすべて返されること
          expect(epic_ids).to include(epic1.id.to_s)
          expect(feature_ids).to include(feature1.id.to_s)
          expect(user_story_ids).to include(user_story1.id.to_s)
          expect(task_ids).to include(task1.id.to_s)

          # 別の階層ツリーは返されないこと
          expect(epic_ids).not_to include(epic2.id.to_s)
          expect(feature_ids).not_to include(feature2.id.to_s)
        end

        it 'returns entire hierarchy when filtering by Task (deepest level)' do
          get :show, params: {
            project_id: project.id,
            filters: { parent_id_in: [task1.id] }
          }

          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)
          epic_ids = json['entities']['epics'].keys
          feature_ids = json['entities']['features'].keys
          user_story_ids = json['entities']['user_stories'].keys
          task_ids = json['entities']['tasks'].keys

          # 曽祖父Epic、祖父Feature、親UserStory、Task自身すべて返されること
          expect(epic_ids).to include(epic1.id.to_s)
          expect(feature_ids).to include(feature1.id.to_s)
          expect(user_story_ids).to include(user_story1.id.to_s)
          expect(task_ids).to include(task1.id.to_s)

          # 別の階層ツリーは返されないこと
          expect(epic_ids).not_to include(epic2.id.to_s)
          expect(feature_ids).not_to include(feature2.id.to_s)
        end
      end

      context 'with multiple parent_id_in values' do
        let!(:user_story_tracker) { create(:user_story_tracker) }

        before do
          project.trackers << [user_story_tracker]
        end

        let!(:user_story1) { create(:user_story, project: project, parent: feature1, author: user, subject: 'US 1') }
        let!(:user_story2) { create(:user_story, project: project, parent: feature2, author: user, subject: 'US 2') }

        it 'returns both hierarchy trees without duplication' do
          get :show, params: {
            project_id: project.id,
            filters: { parent_id_in: [user_story1.id, user_story2.id] }
          }

          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)
          epic_ids = json['entities']['epics'].keys
          feature_ids = json['entities']['features'].keys
          user_story_ids = json['entities']['user_stories'].keys

          # 両方の階層ツリーが返されること
          expect(epic_ids).to include(epic1.id.to_s)
          expect(epic_ids).to include(epic2.id.to_s)
          expect(feature_ids).to include(feature1.id.to_s)
          expect(feature_ids).to include(feature2.id.to_s)
          expect(user_story_ids).to include(user_story1.id.to_s)
          expect(user_story_ids).to include(user_story2.id.to_s)

          # 重複なく各Issueは1回のみ
          expect(epic_ids.count(epic1.id.to_s)).to eq(1)
          expect(epic_ids.count(epic2.id.to_s)).to eq(1)
        end

        it 'handles selecting both parent and child without duplication' do
          # Epic1とその配下のFeature1の両方を選択
          get :show, params: {
            project_id: project.id,
            filters: { parent_id_in: [epic1.id, feature1.id] }
          }

          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)
          epic_ids = json['entities']['epics'].keys
          feature_ids = json['entities']['features'].keys
          user_story_ids = json['entities']['user_stories'].keys

          # Epic1、Feature1、UserStory1すべて返されること
          expect(epic_ids).to include(epic1.id.to_s)
          expect(feature_ids).to include(feature1.id.to_s)
          expect(user_story_ids).to include(user_story1.id.to_s)

          # Epic2の階層は返されないこと
          expect(epic_ids).not_to include(epic2.id.to_s)
          expect(feature_ids).not_to include(feature2.id.to_s)

          # 重複なく各Issueは1回のみ
          expect(epic_ids.count(epic1.id.to_s)).to eq(1)
          expect(feature_ids.count(feature1.id.to_s)).to eq(1)
        end
      end
    end

    context 'when user lacks view_issues permission' do
      let(:unauthorized_role) { create(:role, permissions: []) }
      let(:unauthorized_member) { create(:member, project: project, user: user, roles: [unauthorized_role]) }

      before do
        member.destroy
        unauthorized_member
      end

      it 'returns 403 forbidden' do
        get :show, params: { project_id: project.id }

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when exclude_closed_versions parameter is provided' do
      let!(:version_open) { create(:version, project: project, status: 'open', name: 'v1.0') }
      let!(:version_closed) { create(:version, project: project, status: 'closed', name: 'v2.0') }

      it 'excludes closed versions by default (exclude_closed_versions=true)' do
        get :show, params: {
          project_id: project.id,
          exclude_closed_versions: 'true'
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        version_ids = json['entities']['versions'].keys

        # openバージョンのみが返されること
        expect(version_ids).to include(version_open.id.to_s)
        expect(version_ids).not_to include(version_closed.id.to_s)

        # version_orderにもclosedが含まれないこと
        expect(json['grid']['version_order']).to include(version_open.id.to_s)
        expect(json['grid']['version_order']).not_to include(version_closed.id.to_s)
      end

      it 'includes closed versions when exclude_closed_versions=false' do
        get :show, params: {
          project_id: project.id,
          exclude_closed_versions: 'false'
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        version_ids = json['entities']['versions'].keys

        # すべてのバージョンが返されること
        expect(version_ids).to include(version_open.id.to_s)
        expect(version_ids).to include(version_closed.id.to_s)
      end
    end
  end

  describe 'POST #move_feature' do
    let!(:epic_tracker) { create(:epic_tracker) }
    let!(:feature_tracker) { create(:feature_tracker) }
    let!(:version_v1) { create(:version, project: project) }
    let!(:version_v2) { create(:version, project: project) }

    before do
      project.trackers << [epic_tracker, feature_tracker]
    end

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

    it 'moves feature to target epic' do
      post :move_feature, params: {
        project_id: project.id,
        feature_id: feature.id,
        target_epic_id: target_epic.id,
        target_version_id: version_v2.id
      }

      expect(response).to have_http_status(:ok)

      feature.reload
      expect(feature.parent).to eq(target_epic)
      expect(feature.fixed_version).to eq(version_v2)
    end

    it 'returns error when feature not found' do
      post :move_feature, params: {
        project_id: project.id,
        feature_id: 99999,
        target_epic_id: target_epic.id,
        target_version_id: version_v2.id
      }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #real_time_updates' do
    it 'returns updates response' do
      get :real_time_updates, params: {
        project_id: project.id,
        since: 1.hour.ago.iso8601
      }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json).to have_key('data')
      expect(json).to have_key('meta')
      expect(json['data']).to include(
        'updates',
        'deleted_issues',
        'grid_structure_changes',
        'metadata'
      )
    end
  end

  describe 'POST #reset' do
    it 'returns success response (テスト用)' do
      post :reset, params: { project_id: project.id }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json).to have_key('data')
      expect(json).to have_key('meta')
      expect(json['data']['message']).to be_a(String)
      expect(json['data']).to have_key('deleted_issues_count')
      expect(json['data']['project_id']).to eq(project.id)
    end
  end

  describe 'POST #create_epic' do
    let!(:epic_tracker) { create(:epic_tracker) }

    before do
      project.trackers << epic_tracker
    end

    let(:valid_params) do
      {
        project_id: project.id,
        epic: {
          subject: 'New Epic',
          description: 'Epic description',
          fixed_version_id: nil
        }
      }
    end

    it 'creates new epic' do
      expect {
        post :create_epic, params: valid_params
      }.to change(Issue, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['created_entity']).to include(
        'subject' => 'New Epic'
      )
    end

    it 'returns MSW-compliant response structure' do
      post :create_epic, params: valid_params

      json = JSON.parse(response.body)
      expect(json['data']).to have_key('created_entity')
      expect(json['data']).to have_key('updated_entities')
      expect(json['data']).to have_key('grid_updates')

      # created_entityがepic情報を含むことを確認
      expect(json['data']['created_entity']).to include('subject' => 'New Epic')
    end

    it 'validates required subject field' do
      invalid_params = valid_params.deep_dup
      invalid_params[:epic][:subject] = ''

      post :create_epic, params: invalid_params

      expect(response).to have_http_status(:unprocessable_entity)
    end

    context 'when user lacks add_issues permission' do
      let(:unauthorized_role) { create(:role, permissions: [:view_issues]) }
      let(:unauthorized_member) { create(:member, project: project, user: user, roles: [unauthorized_role]) }

      before do
        member.destroy
        unauthorized_member
      end

      it 'returns 403 forbidden' do
        post :create_epic, params: valid_params

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when epic tracker is not configured' do
      before do
        project.trackers.clear
      end

      it 'returns configuration error' do
        post :create_epic, params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json['error']['details']['error_code']).to eq('EPIC_TRACKER_NOT_FOUND')
      end
    end
  end

  describe 'POST #create_version' do
    let(:valid_params) do
      {
        project_id: project.id,
        version: {
          name: 'v1.0.0',
          description: 'Version 1.0.0 release',
          effective_date: '2025-12-31',
          status: 'open'
        }
      }
    end

    it 'creates new version' do
      expect {
        post :create_version, params: valid_params
      }.to change(Version, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['created_entity']).to include(
        'name' => 'v1.0.0',
        'description' => 'Version 1.0.0 release'
      )
    end

    it 'returns MSW-compliant response structure' do
      post :create_version, params: valid_params

      json = JSON.parse(response.body)
      expect(json['data']).to have_key('created_entity')
      expect(json['data']).to have_key('grid_updates')

      # created_entityがversion情報を含むことを確認
      expect(json['data']['created_entity']).to include('name' => 'v1.0.0')
    end

    it 'validates required name field' do
      invalid_params = valid_params.deep_dup
      invalid_params[:version][:name] = ''

      post :create_version, params: invalid_params

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns error when version name already exists' do
      create(:version, project: project, name: 'v1.0.0')

      post :create_version, params: valid_params

      expect(response).to have_http_status(:unprocessable_entity)

      json = JSON.parse(response.body)
      expect(json['error']['message']).to include('バージョン名が既に存在します')
    end

    context 'when user lacks manage_versions permission' do
      let(:unauthorized_role) { create(:role, permissions: [:view_issues]) }
      let(:unauthorized_member) { create(:member, project: project, user: user, roles: [unauthorized_role]) }

      before do
        member.destroy
        unauthorized_member
      end

      it 'returns 403 forbidden' do
        post :create_version, params: valid_params

        expect(response).to have_http_status(:forbidden)
      end
    end

    it 'includes grid impact metadata' do
      post :create_version, params: valid_params

      json = JSON.parse(response.body)
      expect(json).to have_key('meta')
      expect(json['meta']).to have_key('timestamp')
      expect(json['meta']).to have_key('request_id')
    end
  end

  describe 'GET #show with sort options' do
    let!(:epic_tracker) { create(:epic_tracker) }

    before do
      project.trackers << epic_tracker
    end

    let!(:epic1) { create(:epic, project: project, author: user, subject: 'Zebra Epic', start_date: '2025-03-01') }
    let!(:epic2) { create(:epic, project: project, author: user, subject: 'Apple Epic', start_date: '2025-01-01') }
    let!(:epic3) { create(:epic, project: project, author: user, subject: 'Mango Epic', start_date: '2025-02-01') }
    let!(:version1) { create(:version, project: project, name: 'v3.0', effective_date: '2025-03-15') }
    let!(:version2) { create(:version, project: project, name: 'v1.0', effective_date: '2025-01-10') }
    let!(:version3) { create(:version, project: project, name: 'v2.0', effective_date: '2025-02-20') }

    context 'when sorting epics by subject ascending' do
      it 'returns epics sorted by subject in ascending order' do
        get :show, params: {
          project_id: project.id,
          sort_options: {
            epic: { sort_by: 'subject', sort_direction: 'asc' }
          }
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        epic_order = json['grid']['epic_order']
        expect(epic_order).to eq([epic2.id.to_s, epic3.id.to_s, epic1.id.to_s]) # Apple, Mango, Zebra
      end
    end

    context 'when sorting epics by subject descending' do
      it 'returns epics sorted by subject in descending order' do
        get :show, params: {
          project_id: project.id,
          sort_options: {
            epic: { sort_by: 'subject', sort_direction: 'desc' }
          }
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        epic_order = json['grid']['epic_order']
        expect(epic_order).to eq([epic1.id.to_s, epic3.id.to_s, epic2.id.to_s]) # Zebra, Mango, Apple
      end
    end

    context 'when sorting epics by id ascending' do
      it 'returns epics sorted by id in ascending order' do
        get :show, params: {
          project_id: project.id,
          sort_options: {
            epic: { sort_by: 'id', sort_direction: 'asc' }
          }
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        epic_order = json['grid']['epic_order']
        expect(epic_order).to eq([epic1.id.to_s, epic2.id.to_s, epic3.id.to_s])
      end
    end

    context 'when sorting epics by date ascending' do
      it 'returns epics sorted by start_date in ascending order' do
        get :show, params: {
          project_id: project.id,
          sort_options: {
            epic: { sort_by: 'date', sort_direction: 'asc' }
          }
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        epic_order = json['grid']['epic_order']
        expect(epic_order).to eq([epic2.id.to_s, epic3.id.to_s, epic1.id.to_s]) # 2025-01-01, 02-01, 03-01
      end
    end

    context 'when sorting versions by name ascending' do
      it 'returns versions sorted by name in ascending order' do
        get :show, params: {
          project_id: project.id,
          sort_options: {
            version: { sort_by: 'subject', sort_direction: 'asc' }
          }
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        version_order = json['grid']['version_order']
        # 'none' は常に最後
        expect(version_order[0..2]).to eq([version2.id.to_s, version3.id.to_s, version1.id.to_s]) # v1.0, v2.0, v3.0
        expect(version_order.last).to eq('none')
      end
    end

    context 'when sorting versions by date ascending' do
      it 'returns versions sorted by effective_date in ascending order' do
        get :show, params: {
          project_id: project.id,
          sort_options: {
            version: { sort_by: 'date', sort_direction: 'asc' }
          }
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        version_order = json['grid']['version_order']
        # 'none' は常に最後
        expect(version_order[0..2]).to eq([version2.id.to_s, version3.id.to_s, version1.id.to_s]) # 01-10, 02-20, 03-15
        expect(version_order.last).to eq('none')
      end
    end

    context 'when sorting versions by id descending' do
      it 'returns versions sorted by id in descending order' do
        get :show, params: {
          project_id: project.id,
          sort_options: {
            version: { sort_by: 'id', sort_direction: 'desc' }
          }
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        version_order = json['grid']['version_order']
        # 'none' は常に最後
        expect(version_order[0..2]).to eq([version3.id.to_s, version2.id.to_s, version1.id.to_s])
        expect(version_order.last).to eq('none')
      end
    end
  end

  describe 'POST #move_user_story (バージョン変更時の日付自動設定)' do
    let!(:epic_tracker) { create(:epic_tracker) }
    let!(:feature_tracker) { create(:feature_tracker) }
    let!(:user_story_tracker) { create(:user_story_tracker) }
    let!(:task_tracker) { create(:task_tracker) }
    let!(:test_tracker) { create(:test_tracker) }

    # edit_issues権限を持つroleを使用
    let(:role_with_permissions) { create(:role, permissions: [:view_issues, :edit_issues, :add_issues]) }
    let(:member_with_permissions) { create(:member, project: project, user: user, roles: [role_with_permissions]) }

    before do
      # デフォルトのmemberを削除し、適切な権限を持つmemberに置き換え
      member.destroy
      member_with_permissions

      project.trackers << [epic_tracker, feature_tracker, user_story_tracker, task_tracker, test_tracker]
    end

    let!(:version_v1) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 3, 31)) }
    let!(:version_v2) { create(:version, project: project, name: 'v2.0', effective_date: Date.new(2025, 6, 30)) }
    let!(:epic) { create(:epic, project: project, author: user) }
    let!(:feature) { create(:feature, project: project, parent: epic, author: user) }
    let!(:user_story) do
      create(:user_story,
        project: project,
        parent: feature,
        author: user,
        fixed_version: version_v1
      )
    end
    let!(:task) { create(:task, project: project, parent: user_story, author: user) }
    let!(:test) { create(:test, project: project, parent: user_story, author: user) }

    context 'バージョン変更時' do
      it 'UserStoryの日付が自動設定される' do
        post :move_user_story, params: {
          project_id: project.id,
          user_story_id: user_story.id,
          target_feature_id: feature.id,
          target_version_id: version_v2.id
        }

        expect(response).to have_http_status(:ok)

        user_story.reload
        expect(user_story.fixed_version).to eq(version_v2)
        expect(user_story.start_date).to eq(Date.new(2025, 3, 31))  # version_v1の期日（最も早い）
        expect(user_story.due_date).to eq(Date.new(2025, 6, 30))    # version_v2の期日
      end

      it '子issue（task、test）の日付も自動設定される' do
        post :move_user_story, params: {
          project_id: project.id,
          user_story_id: user_story.id,
          target_feature_id: feature.id,
          target_version_id: version_v2.id
        }

        expect(response).to have_http_status(:ok)

        task.reload
        expect(task.start_date).to eq(Date.new(2025, 3, 31))
        expect(task.due_date).to eq(Date.new(2025, 6, 30))

        test.reload
        expect(test.start_date).to eq(Date.new(2025, 3, 31))
        expect(test.due_date).to eq(Date.new(2025, 6, 30))
      end
    end

    context 'バージョン未変更時' do
      it '日付は変更されない' do
        # 元の日付を設定（update_columnsで直接DBを更新してlock_versionを回避）
        user_story.update_columns(
          start_date: Date.new(2025, 1, 1),
          due_date: Date.new(2025, 1, 31)
        )

        # reloadして最新の状態を取得
        user_story.reload
        old_start_date = user_story.start_date
        old_due_date = user_story.due_date

        post :move_user_story, params: {
          project_id: project.id,
          user_story_id: user_story.id,
          target_feature_id: feature.id,
          target_version_id: version_v1.id  # 同じバージョン
        }

        expect(response).to have_http_status(:ok)

        user_story.reload
        # バージョンが変更されていないので日付も変更されない
        expect(user_story.start_date).to eq(old_start_date)
        expect(user_story.due_date).to eq(old_due_date)
      end
    end
  end

  describe 'POST #batch_update (バージョン変更時の日付自動設定)' do
    let!(:epic_tracker) { create(:epic_tracker) }
    let!(:feature_tracker) { create(:feature_tracker) }
    let!(:user_story_tracker) { create(:user_story_tracker) }
    let!(:task_tracker) { create(:task_tracker) }

    # edit_issues権限を持つroleを使用
    let(:role_with_permissions) { create(:role, permissions: [:view_issues, :edit_issues, :add_issues]) }
    let(:member_with_permissions) { create(:member, project: project, user: user, roles: [role_with_permissions]) }

    before do
      # デフォルトのmemberを削除し、適切な権限を持つmemberに置き換え
      member.destroy
      member_with_permissions

      project.trackers << [epic_tracker, feature_tracker, user_story_tracker, task_tracker]
    end

    let!(:version_v1) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 3, 31)) }
    let!(:version_v2) { create(:version, project: project, name: 'v2.0', effective_date: Date.new(2025, 6, 30)) }
    let!(:epic) { create(:epic, project: project, author: user) }
    let!(:feature) { create(:feature, project: project, parent: epic, author: user) }
    let!(:user_story1) do
      create(:user_story,
        project: project,
        parent: feature,
        author: user,
        fixed_version: version_v1
      )
    end
    let!(:user_story2) do
      create(:user_story,
        project: project,
        parent: feature,
        author: user,
        fixed_version: version_v1
      )
    end
    let!(:task1) { create(:task, project: project, parent: user_story1, author: user) }
    let!(:task2) { create(:task, project: project, parent: user_story2, author: user) }

    context '複数UserStoryのバージョン変更' do
      it '全てのUserStoryの日付が自動設定される' do
        post :batch_update, params: {
          project_id: project.id,
          moved_user_stories: [
            { id: user_story1.id, target_feature_id: feature.id, target_version_id: version_v2.id },
            { id: user_story2.id, target_feature_id: feature.id, target_version_id: version_v2.id }
          ]
        }

        expect(response).to have_http_status(:ok)

        user_story1.reload
        expect(user_story1.start_date).to eq(Date.new(2025, 3, 31))
        expect(user_story1.due_date).to eq(Date.new(2025, 6, 30))

        user_story2.reload
        expect(user_story2.start_date).to eq(Date.new(2025, 3, 31))
        expect(user_story2.due_date).to eq(Date.new(2025, 6, 30))
      end

      it '全ての子issueの日付も自動設定される' do
        post :batch_update, params: {
          project_id: project.id,
          moved_user_stories: [
            { id: user_story1.id, target_feature_id: feature.id, target_version_id: version_v2.id },
            { id: user_story2.id, target_feature_id: feature.id, target_version_id: version_v2.id }
          ]
        }

        expect(response).to have_http_status(:ok)

        task1.reload
        expect(task1.start_date).to eq(Date.new(2025, 3, 31))
        expect(task1.due_date).to eq(Date.new(2025, 6, 30))

        task2.reload
        expect(task2.start_date).to eq(Date.new(2025, 3, 31))
        expect(task2.due_date).to eq(Date.new(2025, 6, 30))
      end

      it 'MSW準拠のレスポンスを返す' do
        post :batch_update, params: {
          project_id: project.id,
          moved_user_stories: [
            { id: user_story1.id, target_feature_id: feature.id, target_version_id: version_v2.id }
          ]
        }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['updated_entities']).to have_key('user_stories')
        expect(json['updated_entities']).to have_key('features')
        expect(json['updated_grid_index']).to be_a(Hash)
      end
    end
  end
end
