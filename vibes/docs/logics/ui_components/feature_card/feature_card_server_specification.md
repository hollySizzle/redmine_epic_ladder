# Feature Card サーバーサイド実装仕様

## 概要
Feature Cardコンポーネント用サーバーサイド実装。Issue階層（Epic→Feature→UserStory→Task/Test/Bug）データ構築・配信、D&D操作、状態遷移処理。

## コントローラー実装

### Feature Card専用コントローラー
```ruby
# app/controllers/kanban/feature_cards_controller.rb
module Kanban
  class FeatureCardsController < ApplicationController
    include KanbanApiConcern

    def show
      @feature = find_feature_with_hierarchy
      render json: {
        feature_card: serialize_feature_card(@feature),
        metadata: feature_metadata(@feature)
      }
    end

    def update_status
      @feature = find_feature
      transition_result = FeatureStateTransition.new(@feature, current_user)
                                                 .transition_to(params[:target_column])

      if transition_result.success?
        render json: {
          updated_feature: serialize_feature_card(@feature.reload),
          affected_relations: serialize_affected_issues(transition_result.affected_issues)
        }
      else
        render json: { error: transition_result.error_message }, status: :unprocessable_entity
      end
    end

    def toggle_user_story_expansion
      user_story = find_user_story
      expansion_state = FeatureCardExpansionState.toggle(current_user, user_story.id)

      render json: {
        user_story_id: user_story.id,
        expanded: expansion_state.expanded?,
        child_items: expansion_state.expanded? ? serialize_child_items(user_story) : []
      }
    end

    def bulk_update
      result = FeatureCardBulkUpdater.new(
        current_user,
        params[:user_story_ids],
        params[:action_type],
        bulk_params
      ).execute

      if result.success?
        render json: {
          updated_user_stories: result.updated_items.map { |us| serialize_user_story(us) },
          generated_items: result.generated_items&.map { |item| serialize_issue(item) } || [],
          statistics: result.statistics
        }
      else
        render json: {
          error: result.error_message,
          failed_items: result.failed_items
        }, status: :unprocessable_entity
      end
    end

    private

    def find_feature_with_hierarchy
      Issue.includes(:tracker, :status, :assigned_to, :fixed_version,
                    children: [:tracker, :status, :assigned_to, :fixed_version, :children])
           .joins(:tracker)
           .where(id: params[:id], trackers: { name: 'Feature' })
           .first!
    end

    def serialize_feature_card(feature)
      {
        issue: serialize_issue(feature),
        user_stories: feature.children
                            .select { |child| child.tracker.name == 'UserStory' }
                            .map { |us| serialize_user_story(us) },
        statistics: calculate_feature_statistics(feature),
        permissions: feature_permissions(feature)
      }
    end

    def serialize_user_story(user_story)
      {
        issue: serialize_issue(user_story),
        child_items: serialize_child_items(user_story),
        statistics: calculate_user_story_statistics(user_story),
        expansion_state: FeatureCardExpansionState.find_by_user_and_item(current_user, user_story.id)&.expanded? || false
      }
    end

    def serialize_child_items(user_story)
      tasks = user_story.children.select { |child| child.tracker.name == 'Task' }
      tests = user_story.children.select { |child| child.tracker.name == 'Test' }
      bugs = user_story.children.select { |child| child.tracker.name == 'Bug' }

      {
        tasks: tasks.map { |task| serialize_base_item(task) },
        tests: tests.map { |test| serialize_base_item(test) },
        bugs: bugs.map { |bug| serialize_base_item(bug) }
      }
    end

    def bulk_params
      params.require(:bulk_action).permit(:version_id, :status_id, :assignee_id, :test_template_id)
    end
  end
end
```

## サービスクラス実装

### Feature Card データビルダー
```ruby
# app/services/kanban/feature_card_data_builder.rb
module Kanban
  class FeatureCardDataBuilder
    def initialize(feature_issue, user, options = {})
      @feature = feature_issue
      @user = user
      @options = options
    end

    def build
      {
        feature_card: build_feature_card_data,
        hierarchy_context: build_hierarchy_context,
        interaction_capabilities: build_interaction_capabilities
      }
    end

    private

    def build_feature_card_data
      {
        feature: serialize_feature_with_metadata,
        user_stories: build_user_stories_data,
        aggregated_statistics: calculate_aggregated_statistics,
        visual_indicators: calculate_visual_indicators
      }
    end

    def serialize_feature_with_metadata
      base_data = serialize_issue(@feature)
      base_data.merge({
        epic_context: @feature.parent ? serialize_issue(@feature.parent) : nil,
        dependency_chain: build_dependency_chain,
        version_propagation: calculate_version_propagation_status,
        release_readiness: calculate_release_readiness
      })
    end

    def build_user_stories_data
      @feature.children
              .select { |child| child.tracker.name == 'UserStory' }
              .map { |user_story| build_user_story_data(user_story) }
              .sort_by { |us_data| [us_data[:priority_order], us_data[:issue][:id]] }
    end

    def build_user_story_data(user_story)
      expansion_state = FeatureCardExpansionState.find_by_user_and_item(@user, user_story.id)

      {
        issue: serialize_issue(user_story),
        child_items: build_child_items_data(user_story),
        statistics: calculate_user_story_statistics(user_story),
        visual_state: {
          expanded: expansion_state&.expanded? || false,
          highlight_completion: should_highlight_completion?(user_story),
          show_warning_indicators: should_show_warnings?(user_story)
        },
        priority_order: calculate_priority_order(user_story)
      }
    end

    def calculate_aggregated_statistics
      all_user_stories = @feature.children.select { |child| child.tracker.name == 'UserStory' }
      all_child_items = all_user_stories.flat_map(&:children)

      {
        user_stories: {
          total: all_user_stories.size,
          completed: all_user_stories.count(&:closed?),
          in_progress: all_user_stories.count { |us| us.status.is_default? == false && !us.closed? }
        },
        child_items: {
          total: all_child_items.size,
          by_type: {
            tasks: all_child_items.count { |item| item.tracker.name == 'Task' },
            tests: all_child_items.count { |item| item.tracker.name == 'Test' },
            bugs: all_child_items.count { |item| item.tracker.name == 'Bug' }
          },
          completed: all_child_items.count(&:closed?)
        },
        overall_completion: calculate_overall_completion_percentage(all_user_stories)
      }
    end
  end
end
```

### Feature Card 展開状態管理
```ruby
# app/models/kanban/feature_card_expansion_state.rb
module Kanban
  class FeatureCardExpansionState < ApplicationRecord
    belongs_to :user

    validates :user_id, presence: true
    validates :user_story_id, presence: true, uniqueness: { scope: :user_id }

    def self.toggle(user, user_story_id)
      state = find_or_initialize_by(user: user, user_story_id: user_story_id)
      state.expanded = !state.expanded?
      state.save!
      state
    end

    def self.find_by_user_and_item(user, user_story_id)
      find_by(user: user, user_story_id: user_story_id)
    end

    def expanded?
      expanded
    end
  end
end
```

### Feature Card 一括更新処理
```ruby
# app/services/kanban/feature_card_bulk_updater.rb
module Kanban
  class FeatureCardBulkUpdater
    def initialize(user, user_story_ids, action_type, action_params)
      @user = user
      @user_story_ids = user_story_ids
      @action_type = action_type
      @action_params = action_params
      @results = BulkUpdateResult.new
    end

    def execute
      validate_permissions!

      case @action_type
      when 'assign_version'
        bulk_assign_version
      when 'update_status'
        bulk_update_status
      when 'generate_tests'
        bulk_generate_tests
      else
        @results.add_error("Unsupported bulk action: #{@action_type}")
      end

      @results
    end

    private

    def bulk_assign_version
      version = Version.find(@action_params[:version_id])
      user_stories = find_user_stories

      user_stories.each do |user_story|
        begin
          user_story.update!(fixed_version: version)
          @results.add_success(user_story)
        rescue => e
          @results.add_failure(user_story, e.message)
        end
      end
    end

    def bulk_generate_tests
      template_id = @action_params[:test_template_id]
      user_stories = find_user_stories

      user_stories.each do |user_story|
        begin
          generator = TestGenerationService.new(user_story, @user, template_id)
          generated_tests = generator.generate
          @results.add_success(user_story)
          @results.add_generated_items(generated_tests)
        rescue => e
          @results.add_failure(user_story, e.message)
        end
      end
    end

    def find_user_stories
      Issue.joins(:tracker)
           .where(id: @user_story_ids, trackers: { name: 'UserStory' })
           .includes(:status, :tracker, :assigned_to, :fixed_version)
    end
  end

  class BulkUpdateResult
    attr_reader :updated_items, :failed_items, :generated_items, :error_message

    def initialize
      @updated_items = []
      @failed_items = []
      @generated_items = []
      @error_messages = []
    end

    def add_success(item)
      @updated_items << item
    end

    def add_failure(item, message)
      @failed_items << { item: item, error: message }
    end

    def success?
      @error_messages.empty? && @failed_items.empty?
    end

    def statistics
      {
        total_processed: @updated_items.size + @failed_items.size,
        successful: @updated_items.size,
        failed: @failed_items.size,
        generated: @generated_items.size
      }
    end
  end
end
```

## ルーティング設定

```ruby
# config/routes.rb
scope 'kanban/projects/:project_id' do
  resources :feature_cards, only: [:show, :update], controller: 'kanban/feature_cards' do
    member do
      patch :update_status
      post 'user_stories/:user_story_id/toggle_expansion',
           action: :toggle_user_story_expansion
    end
    collection do
      patch :bulk_update
    end
  end
end
```

## データベース拡張

```ruby
# db/migrate/create_feature_card_expansion_states.rb
class CreateFeatureCardExpansionStates < ActiveRecord::Migration[6.1]
  def change
    create_table :kanban_feature_card_expansion_states do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :user_story_id, null: false
      t.boolean :expanded, default: false
      t.timestamps
    end

    add_index :kanban_feature_card_expansion_states, [:user_id, :user_story_id],
              unique: true, name: 'idx_expansion_states_user_story'
    add_foreign_key :kanban_feature_card_expansion_states, :issues,
                    column: :user_story_id
  end
end
```

## テスト実装

```ruby
# spec/controllers/kanban/feature_cards_controller_spec.rb
RSpec.describe Kanban::FeatureCardsController do
  let(:project) { create(:project) }
  let(:user) { create(:user_with_kanban_permissions, project: project) }
  let(:feature) { create(:feature_issue, project: project) }

  before { User.current = user }

  describe 'GET show' do
    it 'Feature Cardデータを返す' do
      get :show, params: { project_id: project.id, id: feature.id }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['feature_card']).to include('issue', 'user_stories', 'statistics')
    end
  end

  describe 'PATCH update_status' do
    it 'Feature状態を更新' do
      patch :update_status, params: {
        project_id: project.id,
        id: feature.id,
        target_column: 'in_progress'
      }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH bulk_update' do
    let!(:user_stories) { create_list(:user_story_issue, 3, parent: feature) }

    it '複数UserStoryを一括更新' do
      patch :bulk_update, params: {
        project_id: project.id,
        user_story_ids: user_stories.map(&:id),
        action_type: 'assign_version',
        bulk_action: { version_id: create(:version).id }
      }
      expect(response).to have_http_status(:success)
    end
  end
end
```

---

*Feature Cardコンポーネント用サーバーサイド実装。Issue階層データ構築、D&D操作、一括操作機能*