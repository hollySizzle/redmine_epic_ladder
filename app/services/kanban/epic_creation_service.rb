# frozen_string_literal: true

module Kanban
  # EpicCreationService - Epic作成処理サービス
  # 設計書仕様: Epic作成のバリデーション、Issue作成、統計情報計算
  class EpicCreationService
    class EpicTrackerNotFoundError < StandardError; end
    class InvalidEpicDataError < StandardError; end

    def self.execute(project:, epic_params:, user:)
      new(project, epic_params, user).execute
    end

    def initialize(project, epic_params, user)
      @project = project
      @epic_params = epic_params
      @user = user
    end

    def execute
      Rails.logger.info "[EpicCreationService] Starting epic creation - params: #{@epic_params.inspect}"

      validate_inputs
      Rails.logger.info "[EpicCreationService] Input validation passed"

      ActiveRecord::Base.transaction do
        Rails.logger.info "[EpicCreationService] Starting transaction"

        epic = create_epic_issue
        Rails.logger.info "[EpicCreationService] Epic created successfully - ID: #{epic.id}"

        grid_position = calculate_grid_position(epic)
        Rails.logger.info "[EpicCreationService] Grid position calculated: #{grid_position.inspect}"

        statistics_update = calculate_statistics_update
        Rails.logger.info "[EpicCreationService] Statistics updated: #{statistics_update.inspect}"

        result = {
          success: true,
          epic: epic,
          grid_position: grid_position,
          statistics_update: statistics_update,
          timestamp: Time.current.iso8601
        }

        Rails.logger.info "[EpicCreationService] Epic creation completed successfully"
        result
      end
    rescue EpicTrackerNotFoundError => e
      Rails.logger.error "[EpicCreationService] Epic tracker not found: #{e.message}"
      { success: false, error: e.message, error_code: 'EPIC_TRACKER_NOT_FOUND' }
    rescue InvalidEpicDataError => e
      Rails.logger.error "[EpicCreationService] Invalid epic data: #{e.message}"
      { success: false, error: e.message, error_code: 'INVALID_EPIC_DATA' }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[EpicCreationService] Record validation failed: #{e.message}"
      Rails.logger.error "[EpicCreationService] Validation errors: #{e.record.errors.full_messages.join(', ')}"
      { success: false, error: e.message, error_code: 'RECORD_INVALID', details: e.record.errors.messages }
    rescue => e
      Rails.logger.error "[EpicCreationService] Unexpected error: #{e.message}"
      Rails.logger.error "[EpicCreationService] Backtrace: #{e.backtrace.join("\n")}"
      handle_unexpected_error(e)
    end

    private

    def validate_inputs
      Rails.logger.info "[EpicCreationService] Starting input validation"
      Rails.logger.info "[EpicCreationService] Project: #{@project&.name} (ID: #{@project&.id})"
      Rails.logger.info "[EpicCreationService] User: #{@user&.name} (ID: #{@user&.id})"

      raise InvalidEpicDataError, "プロジェクトが指定されていません" unless @project&.persisted?
      Rails.logger.info "[EpicCreationService] Project validation passed"

      raise InvalidEpicDataError, "Epic件名が指定されていません" if @epic_params[:subject].blank?
      Rails.logger.info "[EpicCreationService] Subject validation passed: '#{@epic_params[:subject]}'"

      # Epic トラッカーの存在確認
      Rails.logger.info "[EpicCreationService] Checking Epic tracker availability for project #{@project.id}"
      epic_tracker_name = Kanban::TrackerHierarchy.tracker_names[:epic]
      epic_tracker = @project.trackers.find_by(name: epic_tracker_name)
      Rails.logger.info "[EpicCreationService] Epic tracker found: #{epic_tracker&.name} (ID: #{epic_tracker&.id})"

      unless epic_tracker
        # 利用可能トラッカー一覧を取得
        available_trackers = @project.trackers.pluck(:name)
        all_system_trackers = Tracker.pluck(:name)

        error_message = build_epic_tracker_error_message(available_trackers, all_system_trackers)
        Rails.logger.error "[EpicCreationService] Epic tracker configuration error: #{error_message}"
        raise EpicTrackerNotFoundError, error_message
      end

      # アサイン先ユーザー検証
      if @epic_params[:assigned_to_id].present?
        Rails.logger.info "[EpicCreationService] Checking assigned user: #{@epic_params[:assigned_to_id]}"
        assigned_user = User.find_by(id: @epic_params[:assigned_to_id])
        Rails.logger.info "[EpicCreationService] Assigned user found: #{assigned_user&.name} (ID: #{assigned_user&.id})"
        raise InvalidEpicDataError, "指定されたアサイン先ユーザーが見つかりません" unless assigned_user
      else
        Rails.logger.info "[EpicCreationService] No assigned user specified"
      end

      Rails.logger.info "[EpicCreationService] All input validations completed successfully"
    end

    def create_epic_issue
      Rails.logger.info "[EpicCreationService] Starting Epic issue creation"

      epic_tracker_name = Kanban::TrackerHierarchy.tracker_names[:epic]
      epic_tracker = @project.trackers.find_by(name: epic_tracker_name)
      Rails.logger.info "[EpicCreationService] Epic tracker: #{epic_tracker.name} (ID: #{epic_tracker.id})"

      # 初期ステータス取得（New または Open）
      initial_status = find_initial_status
      Rails.logger.info "[EpicCreationService] Initial status: #{initial_status&.name} (ID: #{initial_status&.id})"
      raise InvalidEpicDataError, "Epic作成用の初期ステータスが見つかりません" unless initial_status

      # Epic Issue作成
      Rails.logger.info "[EpicCreationService] Building Epic issue with attributes:"
      Rails.logger.info "[EpicCreationService]   subject: '#{@epic_params[:subject]}'"
      Rails.logger.info "[EpicCreationService]   description: '#{@epic_params[:description]}'"
      Rails.logger.info "[EpicCreationService]   tracker_id: #{epic_tracker.id}"
      Rails.logger.info "[EpicCreationService]   status_id: #{initial_status.id}"
      Rails.logger.info "[EpicCreationService]   author_id: #{@user.id}"
      Rails.logger.info "[EpicCreationService]   assigned_to_id: #{@epic_params[:assigned_to_id].presence}"
      Rails.logger.info "[EpicCreationService]   fixed_version_id: #{@epic_params[:fixed_version_id].presence}"

      epic = @project.issues.build(
        subject: @epic_params[:subject],
        description: @epic_params[:description] || '',
        tracker: epic_tracker,
        status: initial_status,
        author: @user,
        assigned_to_id: @epic_params[:assigned_to_id].presence,
        fixed_version_id: @epic_params[:fixed_version_id].presence
      )

      Rails.logger.info "[EpicCreationService] Epic built successfully, attempting to save..."

      if epic.valid?
        Rails.logger.info "[EpicCreationService] Epic validation passed, saving..."
        epic.save!
        Rails.logger.info "[EpicCreationService] Epic saved successfully: #{epic.subject} (id: #{epic.id})"
      else
        Rails.logger.error "[EpicCreationService] Epic validation failed:"
        epic.errors.full_messages.each do |error_msg|
          Rails.logger.error "[EpicCreationService]   - #{error_msg}"
        end
        Rails.logger.error "[EpicCreationService] Epic attributes: #{epic.attributes.inspect}"
        epic.save! # This will trigger the RecordInvalid exception with details
      end

      epic
    end

    def find_initial_status
      # 優先順位順で初期ステータスを探す
      ['New', 'Open', 'ToDo'].each do |status_name|
        status = IssueStatus.find_by(name: status_name)
        return status if status
      end

      # フォールバック: 最初のステータス
      IssueStatus.first
    end

    def calculate_grid_position(epic)
      {
        epic_id: epic.id,
        version_id: epic.fixed_version_id,
        row_position: calculate_epic_row_position(epic),
        column_position: epic.fixed_version_id ? epic.fixed_version.id : nil
      }
    end

    def calculate_epic_row_position(epic)
      # 同プロジェクト内のEpic総数を基に位置を計算
      epic_tracker_name = Kanban::TrackerHierarchy.tracker_names[:epic]
      epics_before = @project.issues
                             .joins(:tracker)
                             .where(trackers: { name: epic_tracker_name })
                             .where('created_on < ?', epic.created_on)
                             .count

      epics_before + 1
    end

    def calculate_statistics_update
      # N+1回避でEpic数を取得
      epic_tracker_name = Kanban::TrackerHierarchy.tracker_names[:epic]
      total_epics = @project.issues.joins(:tracker).where(trackers: { name: epic_tracker_name }).count

      {
        total_epics: total_epics,
        grid_dimensions_changed: true,
        new_row_added: true,
        updated_at: Time.current.iso8601
      }
    end

    def handle_unexpected_error(error)
      Rails.logger.error "#{self.class.name} error: #{error.message}"
      Rails.logger.error error.backtrace.join("\n")

      { success: false, error: 'Epic作成中にシステムエラーが発生しました', error_code: 'SYSTEM_ERROR' }
    end

    def build_epic_tracker_error_message(available_trackers, all_system_trackers)
      base_message = "Epic作成には「Epic」トラッカーが必要ですが、プロジェクト「#{@project.name}」では有効になっていません。"

      # 利用可能トラッカー情報
      if available_trackers.any?
        available_list = available_trackers.join(', ')
        tracker_info = "\n\n【このプロジェクトで利用可能なトラッカー】\n#{available_list}"
      else
        tracker_info = "\n\n【このプロジェクトで利用可能なトラッカー】\nなし"
      end

      # システム全体のトラッカー情報
      if all_system_trackers.include?('Epic')
        system_info = "\n\n【システム情報】\n「Epic」トラッカーはシステムに存在していますが、このプロジェクトでは有効化されていません。"
      else
        system_info = "\n\n【システム情報】\n「Epic」トラッカーがシステムに存在しません。まず管理画面でトラッカーを作成してください。"
      end

      # 設定手順
      setup_guide = <<~GUIDE

        【解決方法】
        1. Redmine管理者でログイン
        2. プロジェクト設定 → 「#{@project.name}」プロジェクト → 「情報」タブ
        3. 「トラッカー」セクションで「Epic」にチェックを入れる
        4. 「保存」をクリック

        または、システム管理者の場合：
        1. 管理 → トラッカー
        2. 「Epic」トラッカーが存在しない場合は「新しいトラッカー」で作成
        3. 上記のプロジェクト設定でEpicトラッカーを有効化
      GUIDE

      base_message + tracker_info + system_info + setup_guide
    end
  end
end