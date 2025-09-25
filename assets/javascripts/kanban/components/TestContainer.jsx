import React from 'react';
import { BaseItemCard } from './BaseItemCard';

/**
 * TestContainer - 設計仕様書完全準拠
 * @vibes/logics/ui_components/feature_card/feature_card_component_specification.md
 */
export const TestContainer = ({
  tests,
  userStoryId,
  onTestAdd,
  onTestUpdate,
  onTestDelete
}) => {
  return (
    <div className="test-container">
      <div className="test-header">
        <span>Test</span>
        <button
          className="add-test-btn"
          onClick={() => onTestAdd(userStoryId)}
        >
          + Test
        </button>
      </div>

      <div className="test-items">
        {tests.map(test => (
          <BaseItemCard
            key={test.id}
            item={test}
            type="Test"
            onUpdate={onTestUpdate}
            onDelete={onTestDelete}
          />
        ))}
      </div>
    </div>
  );
};