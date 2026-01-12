# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::Registry, type: :model do
  describe '.all_tools' do
    it 'returns all MCP tool classes' do
      tools = described_class.all_tools

      expect(tools).to be_an(Array)
      expect(tools).to all(be < MCP::Tool)
    end

    it 'includes all expected tools dynamically' do
      tool_names = described_class.tool_names

      # 作成系ツール
      expect(tool_names).to include('CreateEpicTool')
      expect(tool_names).to include('CreateFeatureTool')
      expect(tool_names).to include('CreateUserStoryTool')
      expect(tool_names).to include('CreateTaskTool')
      expect(tool_names).to include('CreateBugTool')
      expect(tool_names).to include('CreateTestTool')
      expect(tool_names).to include('CreateVersionTool')

      # Version管理ツール
      expect(tool_names).to include('AssignToVersionTool')
      expect(tool_names).to include('MoveToNextVersionTool')
      expect(tool_names).to include('ListVersionsTool')

      # チケット操作ツール
      expect(tool_names).to include('UpdateIssueStatusTool')
      expect(tool_names).to include('UpdateIssueProgressTool')
      expect(tool_names).to include('UpdateIssueAssigneeTool')
      expect(tool_names).to include('UpdateIssueDescriptionTool')
      expect(tool_names).to include('UpdateIssueSubjectTool')
      expect(tool_names).to include('UpdateIssueParentTool')
      expect(tool_names).to include('UpdateCustomFieldsTool')
      expect(tool_names).to include('AddIssueCommentTool')

      # 検索・参照ツール
      expect(tool_names).to include('ListUserStoriesTool')
      expect(tool_names).to include('ListEpicsTool')
      expect(tool_names).to include('GetProjectStructureTool')
      expect(tool_names).to include('GetIssueDetailTool')
    end

    it 'returns current count of tools' do
      expect(described_class.count).to eq(24)
    end
  end

  describe '.tool_keys' do
    it 'returns tool keys in snake_case without _tool suffix' do
      keys = described_class.tool_keys

      expect(keys).to include('create_epic')
      expect(keys).to include('update_issue_status')
      expect(keys).to include('get_issue_detail')

      # _tool接尾辞がないことを確認
      keys.each do |key|
        expect(key).not_to end_with('_tool')
      end
    end
  end

  describe '.tools_by_category' do
    it 'groups tools by category' do
      by_category = described_class.tools_by_category

      expect(by_category).to be_a(Hash)
      expect(by_category.keys).to include(:create_issues)
      expect(by_category.keys).to include(:version_management)
      expect(by_category.keys).to include(:issue_operations)
      expect(by_category.keys).to include(:query_tools)
    end

    it 'categorizes create_* tools (except version) as create_issues' do
      by_category = described_class.tools_by_category

      expect(by_category[:create_issues]).to include('create_epic')
      expect(by_category[:create_issues]).to include('create_feature')
      expect(by_category[:create_issues]).to include('create_user_story')
      expect(by_category[:create_issues]).to include('create_task')
      expect(by_category[:create_issues]).to include('create_bug')
      expect(by_category[:create_issues]).to include('create_test')

      # create_version は version_management
      expect(by_category[:create_issues]).not_to include('create_version')
    end

    it 'categorizes version-related tools as version_management' do
      by_category = described_class.tools_by_category

      expect(by_category[:version_management]).to include('create_version')
      expect(by_category[:version_management]).to include('assign_to_version')
      expect(by_category[:version_management]).to include('move_to_next_version')
      # Note: list_versions is categorized as query_tools (matches /^list_/ pattern)
    end

    it 'categorizes update/add tools as issue_operations' do
      by_category = described_class.tools_by_category

      expect(by_category[:issue_operations]).to include('update_issue_status')
      expect(by_category[:issue_operations]).to include('update_issue_progress')
      expect(by_category[:issue_operations]).to include('update_issue_assignee')
      expect(by_category[:issue_operations]).to include('update_issue_description')
      expect(by_category[:issue_operations]).to include('update_issue_subject')
      expect(by_category[:issue_operations]).to include('update_issue_parent')
      expect(by_category[:issue_operations]).to include('update_custom_fields')
      expect(by_category[:issue_operations]).to include('add_issue_comment')
    end

    it 'categorizes list/get tools as query_tools' do
      by_category = described_class.tools_by_category

      expect(by_category[:query_tools]).to include('list_user_stories')
      expect(by_category[:query_tools]).to include('list_epics')
      expect(by_category[:query_tools]).to include('get_project_structure')
      expect(by_category[:query_tools]).to include('get_issue_detail')
      # list_versions matches /^list_/ pattern, so it's categorized as query_tools
      expect(by_category[:query_tools]).to include('list_versions')
    end
  end

  describe '.tools_by_category_ordered' do
    it 'returns categories in specified order' do
      ordered = described_class.tools_by_category_ordered

      expect(ordered).to be_an(Array)
      categories = ordered.map(&:first)

      expect(categories).to eq(%i[create_issues version_management issue_operations query_tools])
    end

    it 'returns [category, tools] pairs' do
      ordered = described_class.tools_by_category_ordered

      ordered.each do |category, tools|
        expect(category).to be_a(Symbol)
        expect(tools).to be_an(Array)
        expect(tools).to all(be_a(String))
      end
    end
  end

  describe '.category_order' do
    it 'defines the display order of categories' do
      expect(described_class.category_order).to eq(%i[create_issues version_management issue_operations query_tools])
    end
  end

  describe 'dynamic tool detection' do
    it 'scans *_tool.rb files from mcp_tools directory' do
      tools_dir = File.expand_path('../../../../lib/epic_ladder/mcp_tools', __dir__)
      tool_files = Dir.glob(File.join(tools_dir, '*_tool.rb'))

      # ファイル数とツール数が一致することを確認
      expect(described_class.count).to eq(tool_files.count)
    end

    it 'all registered tools are valid MCP::Tool subclasses' do
      described_class.all_tools.each do |tool|
        expect(tool).to be < MCP::Tool
        expect(tool).to respond_to(:call)
        expect(tool).to respond_to(:description_value)
      end
    end
  end

  describe 'integration with ServerController' do
    it 'ServerController uses Registry.all_tools' do
      # ServerControllerのall_mcp_toolsがRegistryを使っていることを確認
      controller = Mcp::ServerController.new
      controller_tools = controller.send(:all_mcp_tools)
      registry_tools = described_class.all_tools

      expect(controller_tools).to eq(registry_tools)
    end
  end
end
