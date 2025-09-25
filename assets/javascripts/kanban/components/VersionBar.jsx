import React, { useState, useCallback } from 'react';
import './VersionBar.scss';

/**
 * Version Bar Component
 * ワイヤーフレーム: VERSION_BAR準拠
 */
const VersionBar = ({
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

  return (
    <div className="version_bar" {...props}>
      <div className="version_bar_header">
        <h3>Versions</h3>
        {permissions.can_manage_versions && (
          <button onClick={() => setShowCreateForm(!showCreateForm)}>
            New Version
          </button>
        )}
      </div>

      <div className="version_list">
        {versions.map(version => (
          <div
            key={version.id}
            className={`version_item ${selectedVersions.has(version.id) ? 'selected' : ''}`}
            onClick={(e) => handleVersionSelect(version.id, e)}
          >
            <span>{version.name}</span>
            <span>{version.status}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default VersionBar;