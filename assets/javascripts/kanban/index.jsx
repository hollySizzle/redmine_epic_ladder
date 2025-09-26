// assets/javascripts/kanban/index.jsx
import React from 'react';
import { createRoot } from 'react-dom/client';
import { KanbanGridLayoutV2 } from './components/KanbanGridLayoutV2';

// DOM読み込み完了後にReactアプリを初期化
document.addEventListener('DOMContentLoaded', function() {
  const container = document.getElementById('kanban-root');

  if (container) {
    // data属性からプロジェクト情報を取得
    const projectId = container.dataset.projectId;
    const currentUser = JSON.parse(container.dataset.currentUser);
    const apiBaseUrl = container.dataset.apiBaseUrl;

    // Reactアプリをマウント
    const root = createRoot(container);
    root.render(
      <KanbanGridLayoutV2
        projectId={parseInt(projectId, 10)}
        currentUser={currentUser}
        dragEnabled={true}
        showStatistics={true}
        enableFiltering={true}
      />
    );
  }
});