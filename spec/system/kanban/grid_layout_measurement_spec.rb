# frozen_string_literal: true

# プラグインの rails_helper を明示的に読み込み
require File.expand_path('../../rails_helper', __dir__)

RSpec.describe 'Kanban Grid Layout Measurement', type: :system do
  let(:project) { create(:project, identifier: 'test-kanban', name: 'Test Kanban Project') }
  let(:user) { create(:user, login: 'testuser', password: 'password123', admin: true) }
  let(:epic_tracker) { Tracker.find_or_create_by!(name: 'Epic') { |t| t.default_status = IssueStatus.first } }
  let(:feature_tracker) { Tracker.find_or_create_by!(name: 'Feature') { |t| t.default_status = IssueStatus.first } }
  let(:version) { create(:version, project: project, name: 'v1.0') }

  before(:each) do
    # プロジェクト設定
    project.trackers << epic_tracker unless project.trackers.include?(epic_tracker)
    project.trackers << feature_tracker unless project.trackers.include?(feature_tracker)
    project.enabled_modules.create!(name: 'kanban') unless project.module_enabled?('kanban')

    # ユーザー権限設定
    role = Role.find_or_create_by!(name: 'Manager') do |r|
      r.permissions = [:view_issues, :add_issues, :edit_issues, :manage_versions]
      r.assignable = true
    end
    Member.create!(user: user, project: project, roles: [role])

    # テストデータ作成
    @epic = create(:issue,
                   project: project,
                   tracker: epic_tracker,
                   subject: 'epic テスト',
                   author: user)

    @feature = create(:issue,
                      project: project,
                      tracker: feature_tracker,
                      subject: 'Feature テスト',
                      parent: @epic,
                      fixed_version: version,
                      author: user)

    # デバッグ情報
    puts "\n=== Debug Info ==="
    puts "Capybara app_host: #{Capybara.app_host}"
    puts "Capybara server_port: #{Capybara.server_port}"
    puts "Capybara current_driver: #{Capybara.current_driver}"
    puts "==================\n"

    # ログイン
    visit '/login'

    # ページ内容を確認
    puts "\n=== Page Title ==="
    puts page.title
    puts "==================\n"

    # エラーページかどうか確認
    if page.has_css?('h1', text: /Error/)
      puts "\n=== ERROR DETECTED ==="
      puts page.text
      puts "=====================\n"
    end

    fill_in 'username', with: user.login
    fill_in 'password', with: 'password123'
    click_button 'Login'

    # カンバンページに移動
    visit "/projects/#{project.identifier}/kanban"

    # Grid 読み込み待機
    expect(page).to have_css('.kanban-grid-body', wait: 10)
  end

  describe 'Grid Structure Integrity' do
    it 'validates grid structure and cell counts' do
      grid_metrics = page.evaluate_script(<<~JS)
        (() => {
          const grid = document.querySelector('.kanban-grid-body');
          if (!grid) return null;

          const computedStyle = window.getComputedStyle(grid);
          const gridColumns = computedStyle.gridTemplateColumns;
          const gridRows = computedStyle.gridTemplateRows;

          // CSS変数取得
          const declaredColumns = grid.style.getPropertyValue('--grid-columns');
          const declaredRows = grid.style.getPropertyValue('--grid-rows');

          // 実際の子要素数（display: contents を考慮）
          const directChildren = Array.from(grid.children);

          // display: contents 要素の検出
          const contentsElements = directChildren.filter(child => {
            const style = window.getComputedStyle(child);
            return style.display === 'contents';
          });

          // 実際のグリッドセル数
          let actualGridCells = directChildren.length;
          contentsElements.forEach(elem => {
            actualGridCells--; // contents 要素自体は削除
            actualGridCells += elem.children.length; // 子要素を追加
          });

          return {
            declaredColumns: parseInt(declaredColumns) || 0,
            declaredRows: parseInt(declaredRows) || 0,
            computedColumns: gridColumns.split(' ').length,
            computedRows: gridRows.split(' ').length,
            directChildrenCount: directChildren.length,
            actualGridCells: actualGridCells,
            contentsElementsCount: contentsElements.length
          };
        })();
      JS

      puts "\n=== Grid Metrics ==="
      puts JSON.pretty_generate(grid_metrics)
      puts "===================\n"

      # 期待値検証
      expect(grid_metrics).not_to be_nil
      expect(grid_metrics['declaredColumns']).to be > 0
      expect(grid_metrics['declaredRows']).to be > 0

      # Grid定義と実際のセル数の整合性
      expected_cells = grid_metrics['declaredColumns'] * grid_metrics['declaredRows']
      expect(grid_metrics['actualGridCells']).to be <= (expected_cells * 1.5)
    end
  end

  describe 'Overflow Detection' do
    it 'detects no overflow in grid elements' do
      overflow_metrics = page.evaluate_script(<<~JS)
        (() => {
          const grid = document.querySelector('.kanban-grid-body');
          if (!grid) return [];

          const allElements = [
            ...grid.querySelectorAll('.epic-row, .no-epic-row, .new-epic-row'),
            ...grid.querySelectorAll('.epic-header-cell, .no-epic-header-cell'),
            ...grid.querySelectorAll('.grid-cell'),
            ...grid.querySelectorAll('.empty-cell-message, .no-epic-empty-state')
          ];

          return allElements.map(el => {
            const rect = el.getBoundingClientRect();
            const isOverflowing =
              el.scrollWidth > el.clientWidth ||
              el.scrollHeight > el.clientHeight;

            const isOutOfViewport =
              rect.right > window.innerWidth ||
              rect.bottom > window.innerHeight ||
              rect.left < 0 ||
              rect.top < 0;

            return {
              selector: el.className,
              dataEpicId: el.dataset.epicId || 'none',
              dimensions: {
                clientWidth: el.clientWidth,
                clientHeight: el.clientHeight,
                scrollWidth: el.scrollWidth,
                scrollHeight: el.scrollHeight
              },
              position: {
                top: rect.top,
                left: rect.left,
                right: rect.right,
                bottom: rect.bottom
              },
              isOverflowing,
              isOutOfViewport,
              overflowAmount: {
                horizontal: Math.max(0, el.scrollWidth - el.clientWidth),
                vertical: Math.max(0, el.scrollHeight - el.clientHeight)
              }
            };
          });
        })();
      JS

      puts "\n=== Overflow Metrics ==="
      puts JSON.pretty_generate(overflow_metrics)
      puts "=======================\n"

      # オーバーフロー要素の検出
      overflowing_elements = overflow_metrics.select { |m| m['isOverflowing'] }
      out_of_viewport_elements = overflow_metrics.select { |m| m['isOutOfViewport'] }

      # レポート生成
      if overflowing_elements.any?
        puts "❌ オーバーフロー要素: #{overflowing_elements.size}"
        overflowing_elements.each do |el|
          puts "  - #{el['selector']}: #{el['overflowAmount']['horizontal']}px 横, #{el['overflowAmount']['vertical']}px 縦"
        end
      end

      if out_of_viewport_elements.any?
        puts "⚠️  ビューポート外要素: #{out_of_viewport_elements.size}"
      end

      # 閾値チェック
      expect(overflowing_elements.size).to eq(0), "#{overflowing_elements.size} elements are overflowing"
    end
  end

end