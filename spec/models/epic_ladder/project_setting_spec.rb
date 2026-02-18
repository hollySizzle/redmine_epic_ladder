# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicLadder::ProjectSetting, type: :model do
  let(:project) { create(:project) }
  let(:setting) { described_class.for_project(project) }

  # テスト用ヘルパー: 直接SQLでレコードを挿入（スキーマキャッシュ問題を回避）
  def insert_project_setting(project, attrs = {})
    columns = ['project_id', 'created_at', 'updated_at']
    values = [project.id, 'NOW()', 'NOW()']

    attrs.each do |key, value|
      columns << key.to_s
      values << (value.nil? ? 'NULL' : value.is_a?(String) ? "'#{value}'" : value)
    end

    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO epic_ladder_project_settings (#{columns.join(', ')})
      VALUES (#{values.join(', ')})
      ON CONFLICT (project_id) DO UPDATE SET
        #{attrs.map { |k, v| "#{k} = #{v.nil? ? 'NULL' : v.is_a?(String) ? "'#{v}'" : v}" }.join(', ')},
        updated_at = NOW()
    SQL
  end

  before do
    # グローバル設定をセットアップ
    Setting.plugin_redmine_epic_ladder = {
      'epic_tracker' => 'GlobalEpic',
      'feature_tracker' => 'GlobalFeature',
      'user_story_tracker' => 'GlobalUserStory',
      'task_tracker' => 'GlobalTask',
      'test_tracker' => 'GlobalTest',
      'bug_tracker' => 'GlobalBug',
      'hierarchy_guide_enabled' => '1',
      'mcp_enabled' => '0'
    }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it 'validates presence of project_id' do
      setting = described_class.new
      expect(setting).not_to be_valid
      expect(setting.errors[:project_id]).to be_present
    end

    it 'validates uniqueness of project_id' do
      described_class.create!(project: project)
      duplicate = described_class.new(project: project)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:project_id]).to include('has already been taken')
    end
  end

  describe '.for_project' do
    it 'returns existing setting for project' do
      existing = described_class.create!(project: project)
      expect(described_class.for_project(project)).to eq(existing)
    end

    it 'initializes new setting if not exists' do
      result = described_class.for_project(project)
      expect(result).to be_a(described_class)
      expect(result).not_to be_persisted
      expect(result.project).to eq(project)
    end
  end

  describe '.get' do
    context 'when project setting is nil (not set)' do
      it 'falls back to global setting for tracker names' do
        expect(described_class.get(project, :epic_tracker)).to eq('GlobalEpic')
        expect(described_class.get(project, :feature_tracker)).to eq('GlobalFeature')
        expect(described_class.get(project, :user_story_tracker)).to eq('GlobalUserStory')
      end

      it 'falls back to global setting for feature flags' do
        expect(described_class.get(project, :hierarchy_guide_enabled)).to eq('1')
        expect(described_class.get(project, :mcp_enabled)).to eq('0')
      end
    end

    context 'when project setting is explicitly set' do
      before do
        insert_project_setting(project,
                               epic_tracker: 'ProjectEpic',
                               feature_tracker: 'ProjectFeature',
                               hierarchy_guide_enabled: false,
                               mcp_enabled: true)
      end

      it 'returns project-specific tracker names' do
        expect(described_class.get(project, :epic_tracker)).to eq('ProjectEpic')
        expect(described_class.get(project, :feature_tracker)).to eq('ProjectFeature')
      end

      it 'returns project-specific feature flags' do
        expect(described_class.get(project, :hierarchy_guide_enabled)).to eq(false)
        expect(described_class.get(project, :mcp_enabled)).to eq(true)
      end

      it 'still falls back for unset values' do
        expect(described_class.get(project, :user_story_tracker)).to eq('GlobalUserStory')
        expect(described_class.get(project, :task_tracker)).to eq('GlobalTask')
      end
    end
  end

  describe '.mcp_enabled?' do
    it 'returns false when global is disabled and project not set' do
      expect(described_class.mcp_enabled?(project)).to be false
    end

    it 'returns true when project explicitly enables' do
      described_class.create!(project: project, mcp_enabled: true)
      expect(described_class.mcp_enabled?(project)).to be true
    end

    it 'returns false when project explicitly disables' do
      Setting.plugin_redmine_epic_ladder = Setting.plugin_redmine_epic_ladder.merge('mcp_enabled' => '1')
      described_class.create!(project: project, mcp_enabled: false)
      expect(described_class.mcp_enabled?(project)).to be false
    end
  end

  describe '.hierarchy_guide_enabled?' do
    it 'returns true when global is enabled and project not set' do
      expect(described_class.hierarchy_guide_enabled?(project)).to be true
    end

    it 'returns false when project explicitly disables' do
      insert_project_setting(project, hierarchy_guide_enabled: false, mcp_enabled: false)
      expect(described_class.hierarchy_guide_enabled?(project)).to be false
    end
  end

  describe '.tracker_names' do
    context 'when project has no overrides' do
      it 'returns global tracker names' do
        names = described_class.tracker_names(project)
        expect(names[:epic]).to eq('GlobalEpic')
        expect(names[:feature]).to eq('GlobalFeature')
        expect(names[:user_story]).to eq('GlobalUserStory')
        expect(names[:task]).to eq('GlobalTask')
        expect(names[:test]).to eq('GlobalTest')
        expect(names[:bug]).to eq('GlobalBug')
      end
    end

    context 'when project has partial overrides' do
      before do
        insert_project_setting(project,
                               epic_tracker: 'MyEpic',
                               feature_tracker: 'MyFeature',
                               mcp_enabled: false)
      end

      it 'returns mix of project and global tracker names' do
        names = described_class.tracker_names(project)
        expect(names[:epic]).to eq('MyEpic')
        expect(names[:feature]).to eq('MyFeature')
        expect(names[:user_story]).to eq('GlobalUserStory')
        expect(names[:task]).to eq('GlobalTask')
      end
    end
  end

  describe '#overridden?' do
    it 'returns true when value is set' do
      insert_project_setting(project, epic_tracker: 'CustomEpic', mcp_enabled: false)
      reloaded = described_class.find_by(project: project)
      expect(reloaded.overridden?(:epic_tracker)).to be true
    end

    it 'returns false when value is nil' do
      insert_project_setting(project, mcp_enabled: false)
      reloaded = described_class.find_by(project: project)
      expect(reloaded.overridden?(:epic_tracker)).to be false
    end
  end

  describe '#reset_to_global!' do
    before do
      insert_project_setting(project,
                             epic_tracker: 'CustomEpic',
                             feature_tracker: 'CustomFeature',
                             mcp_enabled: true,
                             hierarchy_guide_enabled: false)
    end

    it 'resets all settings to nil' do
      reloaded = described_class.find_by(project: project)
      reloaded.reset_to_global!
      reloaded.reload

      expect(reloaded[:epic_tracker]).to be_nil
      expect(reloaded[:feature_tracker]).to be_nil
      expect(reloaded[:mcp_enabled]).to be_nil
      expect(reloaded[:hierarchy_guide_enabled]).to be_nil
    end
  end
end
