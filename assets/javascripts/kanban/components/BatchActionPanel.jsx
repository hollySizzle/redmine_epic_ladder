// assets/javascripts/kanban/components/BatchActionPanel.jsx
import React from 'react';

export const BatchActionPanel = ({ selectedCards, projectId, apiService, onBatchAction, onClearSelection }) => {
  const hasSelection = selectedCards.size > 0;

  if (!hasSelection) {
    return null;
  }

  return (
    <div className="batch-action-panel">
      <span>{selectedCards.size}件選択中</span>
      <button onClick={() => console.log('一括バージョン設定')}>
        バージョン設定
      </button>
      <button onClick={() => console.log('一括状態変更')}>
        状態変更
      </button>
      <button onClick={onClearSelection}>
        選択解除
      </button>
    </div>
  );
};