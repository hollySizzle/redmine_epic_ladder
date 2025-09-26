import React, { useState, useCallback } from 'react';

/**
 * NewEpicRow - 設計書準拠の新Epic作成行コンポーネント
 * 設計書仕様: 新Epic作成フォーム行（設計書76-77行目準拠）
 *
 * @param {Array} versionColumns - Version列配列（レイアウト調整用）
 * @param {Function} onNewEpic - 新Epic作成コールバック
 * @param {boolean} compactMode - コンパクト表示モード
 * @param {number} rowIndex - 行インデックス
 */
export const NewEpicRow = ({
  versionColumns = [],
  onNewEpic,
  compactMode = false,
  rowIndex
}) => {
  // Epic作成状態管理
  const [isCreating, setIsCreating] = useState(false);
  const [newEpicData, setNewEpicData] = useState({
    subject: '',
    description: '',
    assigned_to_id: '',
    priority_id: '',
    estimated_hours: ''
  });

  // フォーム検証状態
  const [validationErrors, setValidationErrors] = useState({});

  // API エラー表示状態
  const [apiError, setApiError] = useState(null);

  // Epic作成開始
  const startCreating = useCallback(() => {
    setIsCreating(true);
    setNewEpicData({
      subject: '',
      description: '',
      assigned_to_id: '',
      priority_id: '',
      estimated_hours: ''
    });
    setValidationErrors({});
    setApiError(null);
  }, []);

  // Epic作成キャンセル
  const cancelCreating = useCallback(() => {
    setIsCreating(false);
    setNewEpicData({
      subject: '',
      description: '',
      assigned_to_id: '',
      priority_id: '',
      estimated_hours: ''
    });
    setValidationErrors({});
    setApiError(null);
  }, []);

  // フォーム検証
  const validateForm = useCallback(() => {
    const errors = {};

    if (!newEpicData.subject.trim()) {
      errors.subject = 'Epic名は必須です';
    }

    if (newEpicData.subject.length > 255) {
      errors.subject = 'Epic名は255文字以内で入力してください';
    }

    if (newEpicData.description.length > 65535) {
      errors.description = '説明は65535文字以内で入力してください';
    }

    if (newEpicData.estimated_hours &&
        (isNaN(newEpicData.estimated_hours) || parseFloat(newEpicData.estimated_hours) < 0)) {
      errors.estimated_hours = '予定工数は0以上の数値で入力してください';
    }

    setValidationErrors(errors);
    return Object.keys(errors).length === 0;
  }, [newEpicData]);

  // Epic作成実行
  const handleCreateEpic = useCallback(async () => {
    if (!validateForm()) {
      return;
    }

    try {
      console.log('[NewEpicRow] Creating new Epic:', newEpicData);

      const createdEpic = await onNewEpic({
        ...newEpicData,
        tracker_id: 'Epic', // Redmine設定に依存
        status_id: 1, // 新規状態
        priority_id: newEpicData.priority_id || 2 // デフォルト優先度
      });

      if (createdEpic) {
        // 作成成功時の処理
        setIsCreating(false);
        setNewEpicData({
          subject: '',
          description: '',
          assigned_to_id: '',
          priority_id: '',
          estimated_hours: ''
        });
        console.log('[NewEpicRow] Epic created successfully:', createdEpic);
      }
    } catch (error) {
      console.error('[NewEpicRow] Epic作成エラー:', error);
      console.error('[NewEpicRow] Error message:', error.message);
      console.error('[NewEpicRow] Error details:', error.details);
      console.error('[NewEpicRow] Error status:', error.status);

      // APIエラー情報を状態に保存（詳細表示用）
      setApiError({
        message: error.message || 'Epic作成に失敗しました',
        details: error.details || {},
        status: error.status || 0
      });
    }
  }, [newEpicData, onNewEpic, validateForm]);

  // Enter キー処理
  const handleKeyPress = useCallback((e) => {
    if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) {
      handleCreateEpic();
    } else if (e.key === 'Escape') {
      cancelCreating();
    }
  }, [handleCreateEpic, cancelCreating]);

  return (
    <div
      className={`new-epic-row ${compactMode ? 'compact' : ''}`}
      data-row-index={rowIndex}
    >
      {!isCreating ? (
        // 新Epic作成ボタン表示
        <div className="new-epic-button-container">
          <button
            className="new-epic-button"
            onClick={startCreating}
            title="新しいEpicを作成"
          >
            <span className="plus-icon">+</span>
            <span className="button-text">New Epic</span>
          </button>

          <div className="new-epic-hint">
            <small>プロジェクトに新しいEpicを追加します</small>
          </div>
        </div>
      ) : (
        // Epic作成フォーム表示
        <div className="new-epic-form-container">
          <div className="new-epic-form">
            <h5 className="form-title">新Epic作成</h5>

            {/* API エラー表示 */}
            {apiError && (
              <div className="api-error-display">
                <div className="error-message primary">
                  {apiError.message}
                </div>
                {apiError.details.error_code === 'EPIC_TRACKER_NOT_FOUND' && apiError.details.help_url && (
                  <div className="error-help">
                    <p>
                      <strong>解決方法:</strong>
                      プロジェクトの管理者がEpicトラッカーを有効にする必要があります。
                    </p>
                    <a href={apiError.details.help_url} target="_blank" rel="noopener noreferrer">
                      設定手順を確認 →
                    </a>
                  </div>
                )}
                <button
                  type="button"
                  className="error-dismiss"
                  onClick={() => setApiError(null)}
                  title="エラーメッセージを閉じる"
                >
                  ×
                </button>
              </div>
            )}

            <div className="form-content">
              {/* 基本情報入力 */}
              <div className="basic-info-section">
                <div className="form-group">
                  <label htmlFor="epic-subject" className="form-label">
                    Epic名 <span className="required">*</span>
                  </label>
                  <input
                    id="epic-subject"
                    type="text"
                    placeholder="Epic名を入力してください"
                    value={newEpicData.subject}
                    onChange={(e) => setNewEpicData({
                      ...newEpicData,
                      subject: e.target.value
                    })}
                    onKeyDown={handleKeyPress}
                    className={`form-input ${validationErrors.subject ? 'error' : ''}`}
                    autoFocus
                    maxLength="255"
                  />
                  {validationErrors.subject && (
                    <div className="error-message">{validationErrors.subject}</div>
                  )}
                </div>

                <div className="form-group">
                  <label htmlFor="epic-description" className="form-label">
                    説明
                  </label>
                  <textarea
                    id="epic-description"
                    placeholder="Epicの詳細説明（任意）"
                    value={newEpicData.description}
                    onChange={(e) => setNewEpicData({
                      ...newEpicData,
                      description: e.target.value
                    })}
                    className={`form-textarea ${validationErrors.description ? 'error' : ''}`}
                    rows="3"
                    maxLength="65535"
                  />
                  {validationErrors.description && (
                    <div className="error-message">{validationErrors.description}</div>
                  )}
                </div>
              </div>

              {/* 詳細設定（コンパクトモード時は折りたたみ） */}
              <div className={`advanced-info-section ${compactMode ? 'collapsible' : ''}`}>
                <div className="form-row">
                  <div className="form-group">
                    <label htmlFor="epic-assigned" className="form-label">
                      担当者
                    </label>
                    <select
                      id="epic-assigned"
                      value={newEpicData.assigned_to_id}
                      onChange={(e) => setNewEpicData({
                        ...newEpicData,
                        assigned_to_id: e.target.value
                      })}
                      className="form-select"
                    >
                      <option value="">担当者未設定</option>
                      {/* TODO: 実際のユーザーリストを動的に読み込み */}
                      <option value="1">プロジェクトマネージャー</option>
                      <option value="2">開発リーダー</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label htmlFor="epic-priority" className="form-label">
                      優先度
                    </label>
                    <select
                      id="epic-priority"
                      value={newEpicData.priority_id}
                      onChange={(e) => setNewEpicData({
                        ...newEpicData,
                        priority_id: e.target.value
                      })}
                      className="form-select"
                    >
                      <option value="">優先度未設定</option>
                      <option value="1">低</option>
                      <option value="2">通常</option>
                      <option value="3">高</option>
                      <option value="4">緊急</option>
                      <option value="5">即時</option>
                    </select>
                  </div>
                </div>

                <div className="form-group">
                  <label htmlFor="epic-hours" className="form-label">
                    予定工数（時間）
                  </label>
                  <input
                    id="epic-hours"
                    type="number"
                    placeholder="0"
                    value={newEpicData.estimated_hours}
                    onChange={(e) => setNewEpicData({
                      ...newEpicData,
                      estimated_hours: e.target.value
                    })}
                    className={`form-input ${validationErrors.estimated_hours ? 'error' : ''}`}
                    min="0"
                    step="0.25"
                  />
                  {validationErrors.estimated_hours && (
                    <div className="error-message">{validationErrors.estimated_hours}</div>
                  )}
                </div>
              </div>
            </div>

            {/* フォームアクション */}
            <div className="form-actions">
              <button
                onClick={handleCreateEpic}
                disabled={!newEpicData.subject.trim()}
                className="create-button primary"
              >
                Epic作成
              </button>
              <button
                onClick={cancelCreating}
                className="cancel-button"
              >
                キャンセル
              </button>
            </div>

            {/* キーボードショートカットヒント */}
            <div className="form-hints">
              <small>
                Ctrl+Enter: 作成 | Escape: キャンセル
              </small>
            </div>
          </div>

          {/* Version列との整合性確保（レイアウト調整） */}
          <div className="form-spacer" style={{
            '--version-columns': versionColumns.length
          }}>
            {/* Version列数に応じたスペーサー */}
          </div>
        </div>
      )}
    </div>
  );
};

export default NewEpicRow;