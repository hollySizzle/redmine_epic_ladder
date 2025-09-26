// assets/javascripts/kanban/components/VersionBar.jsx
import React, { useState, useEffect } from 'react';
import { useDroppable } from '@dnd-kit/core';
import { VersionAPI } from '../utils/VersionAPI';
import { CreateVersionModal } from './CreateVersionModal';

export const VersionBar = ({ projectId, onVersionChange }) => {
  const [versions, setVersions] = useState([]);
  const [showCreateModal, setShowCreateModal] = useState(false);

  useEffect(() => {
    fetchVersions();
  }, [projectId]);

  const fetchVersions = async () => {
    try {
      const data = await VersionAPI.getProjectVersions(projectId);
      setVersions(data);
    } catch (error) {
      console.error('バージョン取得エラー:', error);
    }
  };

  const handleCreateVersion = async (versionData) => {
    try {
      const newVersion = await VersionAPI.createVersion(projectId, versionData);
      setVersions([...versions, newVersion]);
      setShowCreateModal(false);
      onVersionChange?.();
    } catch (error) {
      console.error('バージョン作成エラー:', error);
    }
  };

  return (
    <div className="version-bar">
      <div className="version-tabs">
        {versions.map(version => (
          <VersionTab
            key={version.id}
            version={version}
            projectId={projectId}
            onAssignmentChange={onVersionChange}
          />
        ))}
        <button
          className="create-version-btn"
          onClick={() => setShowCreateModal(true)}
        >
          + 新規
        </button>
      </div>

      {showCreateModal && (
        <CreateVersionModal
          onSubmit={handleCreateVersion}
          onClose={() => setShowCreateModal(false)}
        />
      )}
    </div>
  );
};

const VersionTab = ({ version, projectId, onAssignmentChange }) => {
  const { setNodeRef, isOver } = useDroppable({
    id: `version-${version.id}`,
    data: { type: 'version', version }
  });

  const handleDrop = async (cardData) => {
    try {
      await VersionAPI.assignVersion(projectId, cardData.issue.id, version.id);
      onAssignmentChange?.();
    } catch (error) {
      console.error('バージョン割当エラー:', error);
    }
  };

  return (
    <div
      ref={setNodeRef}
      className={`version-tab ${isOver ? 'drop-hover' : ''}`}
      data-version-id={version.id}
    >
      <span className="version-name">{version.name}</span>
      <span className="version-due-date">{version.due_date}</span>
    </div>
  );
};