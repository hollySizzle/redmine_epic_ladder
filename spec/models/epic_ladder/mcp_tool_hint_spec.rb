# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicLadder::McpToolHint, type: :model do
  let(:project) { create(:project) }

  describe 'validations' do
    it 'requires project_id' do
      hint = described_class.new(tool_key: 'create_task', hint_text: 'test')
      expect(hint).not_to be_valid
      expect(hint.errors[:project_id]).to be_present
    end

    it 'requires tool_key' do
      hint = described_class.new(project: project, hint_text: 'test')
      expect(hint).not_to be_valid
      expect(hint.errors[:tool_key]).to be_present
    end

    it 'validates tool_key is in MODIFYING_TOOLS' do
      hint = described_class.new(project: project, tool_key: 'invalid_tool', hint_text: 'test')
      expect(hint).not_to be_valid
      expect(hint.errors[:tool_key]).to include('無効なツールキーです')
    end

    it 'validates uniqueness of tool_key per project' do
      create(:mcp_tool_hint, project: project, tool_key: 'create_task')
      duplicate = build(:mcp_tool_hint, project: project, tool_key: 'create_task')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:tool_key]).to include('has already been taken')
    end

    it 'allows same tool_key for different projects' do
      other_project = create(:project)
      create(:mcp_tool_hint, project: project, tool_key: 'create_task')
      hint = build(:mcp_tool_hint, project: other_project, tool_key: 'create_task')
      expect(hint).to be_valid
    end

    it 'validates hint_text max length' do
      hint = described_class.new(
        project: project,
        tool_key: 'create_task',
        hint_text: 'a' * 501
      )
      expect(hint).not_to be_valid
      expect(hint.errors[:hint_text]).to include(/is too long/)
    end

    it 'accepts hint_text up to 500 characters' do
      hint = described_class.new(
        project: project,
        tool_key: 'create_task',
        hint_text: 'a' * 500
      )
      expect(hint).to be_valid
    end
  end

  describe '.modifying_tools' do
    it 'returns tools from Registry' do
      tools = described_class.modifying_tools
      # Registryからデータ変更系ツールを取得することを確認
      expect(tools).to be_an(Array)
      expect(tools).not_to be_empty
      # query_tools (list_*, get_*) は含まれない
      expect(tools).not_to include(a_string_matching(/^list_/))
      expect(tools).not_to include(a_string_matching(/^get_/))
      # データ変更系ツールが含まれる
      expect(tools).to include('create_task')
      expect(tools).to include('update_issue_status')
    end

    it 'is accessible via MODIFYING_TOOLS for backward compatibility' do
      expect(described_class::MODIFYING_TOOLS).to eq(described_class.modifying_tools)
    end
  end

  describe '.for_tool' do
    context 'when hint exists' do
      let!(:existing_hint) { create(:mcp_tool_hint, project: project, tool_key: 'create_task') }

      it 'returns existing hint' do
        hint = described_class.for_tool(project, 'create_task')
        expect(hint).to eq(existing_hint)
        expect(hint).to be_persisted
      end
    end

    context 'when hint does not exist' do
      it 'returns new hint with project and tool_key set' do
        hint = described_class.for_tool(project, 'create_task')
        expect(hint).not_to be_persisted
        expect(hint.project).to eq(project)
        expect(hint.tool_key).to eq('create_task')
      end
    end
  end

  describe '.hint_for' do
    context 'when enabled hint exists with text' do
      let(:hint_text) { I18n.t('epic_ladder.mcp_hint_examples.task_review') }

      before do
        create(:mcp_tool_hint,
               project: project,
               tool_key: 'create_task',
               hint_text: hint_text,
               enabled: true)
      end

      it 'returns hint text' do
        expect(described_class.hint_for(project, 'create_task')).to eq(hint_text)
      end
    end

    context 'when hint is disabled' do
      let(:hint_text) { I18n.t('epic_ladder.mcp_hint_examples.task_review') }

      before do
        create(:mcp_tool_hint,
               project: project,
               tool_key: 'create_task',
               hint_text: hint_text,
               enabled: false)
      end

      it 'returns nil' do
        expect(described_class.hint_for(project, 'create_task')).to be_nil
      end
    end

    context 'when hint text is blank' do
      before do
        create(:mcp_tool_hint,
               project: project,
               tool_key: 'create_task',
               hint_text: '',
               enabled: true)
      end

      it 'returns nil' do
        expect(described_class.hint_for(project, 'create_task')).to be_nil
      end
    end

    context 'when hint does not exist' do
      context 'and global hint exists' do
        before do
          Setting.plugin_redmine_epic_ladder = Setting.plugin_redmine_epic_ladder.merge(
            'mcp_tool_hints' => {
              'create_task' => { 'enabled' => '1', 'hint_text' => 'グローバルルール' }
            }
          )
        end

        it 'falls back to global hint' do
          expect(described_class.hint_for(project, 'create_task')).to eq('グローバルルール')
        end
      end

      context 'and global hint does not exist' do
        before do
          Setting.plugin_redmine_epic_ladder = Setting.plugin_redmine_epic_ladder.merge(
            'mcp_tool_hints' => {}
          )
        end

        it 'returns nil' do
          expect(described_class.hint_for(project, 'create_task')).to be_nil
        end
      end

      context 'and global hint is disabled' do
        before do
          Setting.plugin_redmine_epic_ladder = Setting.plugin_redmine_epic_ladder.merge(
            'mcp_tool_hints' => {
              'create_task' => { 'enabled' => '0', 'hint_text' => 'グローバルルール' }
            }
          )
        end

        it 'returns nil' do
          expect(described_class.hint_for(project, 'create_task')).to be_nil
        end
      end
    end

    context 'when project hint exists but is disabled' do
      before do
        create(:mcp_tool_hint,
               project: project,
               tool_key: 'create_task',
               hint_text: 'プロジェクトルール',
               enabled: false)
        Setting.plugin_redmine_epic_ladder = Setting.plugin_redmine_epic_ladder.merge(
          'mcp_tool_hints' => {
            'create_task' => { 'enabled' => '1', 'hint_text' => 'グローバルルール' }
          }
        )
      end

      it 'falls back to global hint' do
        expect(described_class.hint_for(project, 'create_task')).to eq('グローバルルール')
      end
    end
  end

  describe '.global_hint_for' do
    context 'when global hint is enabled with text' do
      before do
        Setting.plugin_redmine_epic_ladder = Setting.plugin_redmine_epic_ladder.merge(
          'mcp_tool_hints' => {
            'create_task' => { 'enabled' => '1', 'hint_text' => 'グローバルルール' }
          }
        )
      end

      it 'returns hint text' do
        expect(described_class.global_hint_for('create_task')).to eq('グローバルルール')
      end
    end

    context 'when global hint is disabled' do
      before do
        Setting.plugin_redmine_epic_ladder = Setting.plugin_redmine_epic_ladder.merge(
          'mcp_tool_hints' => {
            'create_task' => { 'enabled' => '0', 'hint_text' => 'グローバルルール' }
          }
        )
      end

      it 'returns nil' do
        expect(described_class.global_hint_for('create_task')).to be_nil
      end
    end

    context 'when global hint text is blank' do
      before do
        Setting.plugin_redmine_epic_ladder = Setting.plugin_redmine_epic_ladder.merge(
          'mcp_tool_hints' => {
            'create_task' => { 'enabled' => '1', 'hint_text' => '' }
          }
        )
      end

      it 'returns nil' do
        expect(described_class.global_hint_for('create_task')).to be_nil
      end
    end

    context 'when global hint does not exist' do
      before do
        Setting.plugin_redmine_epic_ladder = Setting.plugin_redmine_epic_ladder.merge(
          'mcp_tool_hints' => {}
        )
      end

      it 'returns nil' do
        expect(described_class.global_hint_for('create_task')).to be_nil
      end
    end
  end

  describe '.build_description' do
    let(:base_description) { 'Taskチケットを作成します' }
    let(:hint_text) { I18n.t('epic_ladder.mcp_hint_examples.task_review') }

    context 'when project has enabled hint' do
      before do
        create(:mcp_tool_hint,
               project: project,
               tool_key: 'create_task',
               hint_text: hint_text,
               enabled: true)
      end

      it 'appends hint to description' do
        result = described_class.build_description(project, 'create_task', base_description)
        expect(result).to eq("Taskチケットを作成します【ルール】#{hint_text}")
      end
    end

    context 'when project has no hint' do
      it 'returns base description' do
        result = described_class.build_description(project, 'create_task', base_description)
        expect(result).to eq(base_description)
      end
    end

    context 'when hint is disabled' do
      before do
        create(:mcp_tool_hint,
               project: project,
               tool_key: 'create_task',
               hint_text: hint_text,
               enabled: false)
      end

      it 'returns base description' do
        result = described_class.build_description(project, 'create_task', base_description)
        expect(result).to eq(base_description)
      end
    end
  end

  describe '#tool_display_name' do
    it 'returns localized tool name' do
      hint = build(:mcp_tool_hint, tool_key: 'create_task')
      # I18n fallback to titleized key if translation missing
      expect(hint.tool_display_name).to be_present
    end
  end
end
