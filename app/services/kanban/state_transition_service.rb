# frozen_string_literal: true

module Kanban
  # 状態遷移管理サービス
  # カラム移動時の状態遷移制御とワークフロー整合性チェック
  class StateTransitionService
    # カラムと状態のマッピング定義
    COLUMN_STATUS_MAPPING = {
      'backlog' => ['New', 'Open'],
      'ready' => ['Ready'],
      'in_progress' => ['In Progress', 'Assigned'],
      'review' => ['Review', 'Ready for Test'],
      'testing' => ['Testing', 'QA'],
      'done' => ['Resolved', 'Closed']
    }.freeze

    # カンバンカラム移動時の状態遷移処理
    def self.transition_to_column(issue, target_column)
      return { error: '不正なカラム' } unless COLUMN_STATUS_MAPPING.key?(target_column)

      target_statuses = COLUMN_STATUS_MAPPING[target_column]
      current_status = issue.status.name

      # 既に適切な状態の場合は何もしない
      return { unchanged: true, current_status: current_status } if target_statuses.include?(current_status)

      # 遷移可能な状態を取得
      available_status = find_available_status(issue, target_statuses)
      return { error: '遷移可能な状態がありません' } unless available_status

      # ブロック条件チェック
      block_check = check_transition_blocks(issue, available_status)
      return block_check if block_check[:blocked]

      # 状態を更新
      update_issue_status(issue, available_status)
    rescue => e
      { error: e.message }
    end

    # 状態遷移のブロック条件をチェック
    def self.check_transition_blocks(issue, target_status)
      blocks = []

      # UserStoryの場合、子Taskの完了チェック
      tracker_names = Kanban::TrackerHierarchy.tracker_names
      if issue.tracker.name == tracker_names[:user_story] && target_status.name.in?(['Testing', 'Resolved'])
        incomplete_tasks = issue.children.joins(:tracker, :status)
                                .where(trackers: { name: tracker_names[:task] })
                                .where.not(issue_statuses: { name: ['Resolved', 'Closed'] })

        if incomplete_tasks.any?
          blocks << "未完了のTask: #{incomplete_tasks.pluck(:subject).join(', ')}"
        end
      end

      # Testの合格チェック
      if issue.tracker.name == tracker_names[:user_story] && target_status.name == 'Resolved'
        failed_tests = issue.children.joins(:tracker, :status)
                            .where(trackers: { name: tracker_names[:test] })
                            .where(issue_statuses: { name: ['Failed', 'Rejected'] })

        if failed_tests.any?
          blocks << "失敗したTest: #{failed_tests.pluck(:subject).join(', ')}"
        end
      end

      { blocked: blocks.any?, blocks: blocks }
    end

    private

    def self.find_available_status(issue, target_statuses)
      available_statuses = issue.new_statuses_allowed_to(User.current)
      target_statuses.each do |status_name|
        status = available_statuses.find { |s| s.name == status_name }
        return status if status
      end
      nil
    end

    def self.update_issue_status(issue, status)
      issue.update!(status: status)
      {
        success: true,
        old_status: issue.status_id_before_last_save&.then { |id| IssueStatus.find(id).name },
        new_status: status.name
      }
    end
  end
end