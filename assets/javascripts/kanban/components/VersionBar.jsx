// assets/javascripts/kanban/components/VersionBar.jsx
import React from 'react';

export const VersionBar = ({ projectId, apiService, onVersionChange }) => {
  return (
    <div className="version-bar">
      <div className="version-tabs">
        <div className="version-tab">
          <span className="version-name">Backlog-1</span>
          <span className="version-due-date">2024-03-31</span>
        </div>
        <div className="version-tab">
          <span className="version-name">Backlog-2</span>
          <span className="version-due-date">2024-06-30</span>
        </div>
        <button className="create-version-btn">
          + 新規
        </button>
      </div>
    </div>
  );
};