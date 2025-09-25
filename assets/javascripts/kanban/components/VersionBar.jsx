import { useState, useCallback } from 'react';

/**
 * VersionBar Component
 * KanbanGridLayout統合用バージョン管理バー
 * ワイヤーフレーム準拠: バージョン列ヘッダーとして機能
 */
export const VersionBar = ({
  versions = [],
  selectedVersions = new Set(),
  onVersionSelect,
  onVersionCreate,
  permissions = {},
  ...props
}) => {
  const [showCreateForm, setShowCreateForm] = useState(false);

  const handleVersionSelect = useCallback((versionId, event) => {
    event.preventDefault();
    const isSelected = selectedVersions.has(versionId);
    onVersionSelect?.(versionId, !isSelected);
  }, [selectedVersions, onVersionSelect]);

  const handleNewVersionAction = useCallback(() => {
    if (onVersionCreate) {
      onVersionCreate();
    } else {
      setShowCreateForm(!showCreateForm);
    }
  }, [onVersionCreate, showCreateForm]);

  return (
    <div className="version-bar" {...props}>
      <div className="version-bar-header">
        <h3 className="version-bar-title">Versions</h3>
        {permissions.can_manage_versions && (
          <button
            className="new-version-btn"
            onClick={handleNewVersionAction}
            title="新しいVersionを作成"
          >
            + New Version
          </button>
        )}
      </div>

      <div className="version-list">
        {versions.map(version => (
          <div
            key={version.id}
            className={`version-item ${selectedVersions.has(version.id) ? 'selected' : ''}`}
            onClick={(e) => handleVersionSelect(version.id, e)}
          >
            <span className="version-name">{version.name}</span>
            <span className="version-status">{version.status}</span>
            {version.issue_count !== undefined && (
              <span className="version-issue-count">
                {version.issue_count} issues
              </span>
            )}
          </div>
        ))}
      </div>

      {showCreateForm && (
        <div className="version-create-form">
          <input
            type="text"
            placeholder="Version名を入力"
            className="version-name-input"
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                const versionName = e.target.value.trim();
                if (versionName) {
                  onVersionCreate?.({ name: versionName });
                  setShowCreateForm(false);
                  e.target.value = '';
                }
              } else if (e.key === 'Escape') {
                setShowCreateForm(false);
                e.target.value = '';
              }
            }}
            autoFocus
          />
          <div className="version-create-actions">
            <button
              className="btn btn-primary btn-small"
              onClick={(e) => {
                const input = e.target.parentElement.previousElementSibling;
                const versionName = input.value.trim();
                if (versionName) {
                  onVersionCreate?.({ name: versionName });
                  setShowCreateForm(false);
                  input.value = '';
                }
              }}
            >
              作成
            </button>
            <button
              className="btn btn-secondary btn-small"
              onClick={() => setShowCreateForm(false)}
            >
              キャンセル
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

// default export も追加（後方互換性のため）
export default VersionBar;