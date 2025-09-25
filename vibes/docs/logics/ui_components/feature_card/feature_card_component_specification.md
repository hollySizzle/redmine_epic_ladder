# Feature Card コンポーネント設計仕様書

## 🔗 関連ドキュメント
- @vibes/specs/ui/kanban_ui_feature_card_component.drawio
- @vibes/specs/ui/kanban_ui_grid_layout.drawio
- @vibes/rules/technical_architecture_standards.md
- @vibes/logics/kanban_ui_implementation.md

## 1. 概要

ワイヤーフレーム準拠のFeature Cardコンポーネント設計。折り畳み可能な階層構造（Feature → UserStory → Task/Test/Bug）でカード表示を実現。

## 2. コンポーネント階層構造

### 2.1 メインコンポーネント階層
```
FeatureCard (GROUP_FEATURE_CARD)
├── FeatureHeader (GROUP_FEATURE_HEADER)
│   ├── FeatureTitle
│   └── FeatureStatusBadge
├── UserStoryList (GROUP_USER_STORY_LIST)
│   └── UserStory[] (GROUP_USER_STORY_1/2...)
│       ├── UserStoryHeader (GROUP_USER_STORY_HEADER_*)
│       │   ├── CollapseButton
│       │   ├── UserStoryTitle
│       │   ├── UserStoryStatus
│       │   └── UserStoryDeleteButton
│       ├── TaskContainer (GROUP_TASK_CONTAINER_*)
│       │   ├── TaskHeader + AddTaskButton
│       │   └── TaskItem[] (GROUP_TASK_ITEM_*)
│       │       ├── TaskCard (GROUP_TASK_CARD_*)
│       │       │   ├── TaskName
│       │       │   ├── TaskAssignee
│       │       │   └── TaskDeleteButton
│       │       └── TaskStatus
│       ├── TestContainer (GROUP_TEST_CONTAINER_*)
│       │   ├── TestHeader + AddTestButton
│       │   └── TestItem[] (GROUP_TEST_ITEM_*)
│       │       ├── TestCard (GROUP_TEST_CARD_*)
│       │       │   ├── TestName
│       │       │   ├── TestAssignee
│       │       │   └── TestDeleteButton
│       │       └── TestStatus
│       └── BugContainer (GROUP_BUG_CONTAINER_*)
│           ├── BugHeader + AddBugButton
│           └── BugItem[] (GROUP_BUG_ITEM_*)
│               ├── BugCard (GROUP_BUG_CARD_*)
│               │   ├── BugName
│               │   ├── BugAssignee
│               │   └── BugDeleteButton
│               └── BugStatus
```

## 3. React コンポーネント分解設計

### 3.1 FeatureCard (メインコンポーネント)

```javascript
// assets/javascripts/kanban/components/FeatureCard.jsx
import React, { useState, useCallback } from 'react';
import { FeatureHeader } from './FeatureHeader';
import { UserStoryList } from './UserStoryList';
import { useDraggable } from '@dnd-kit/core';

export const FeatureCard = ({
  feature,
  expanded = true,
  onToggle,
  onUserStoryAdd,
  onUserStoryUpdate,
  onUserStoryDelete
}) => {
  const [userStoriesExpanded, setUserStoriesExpanded] = useState(new Map());

  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({
    id: `feature-${feature.issue.id}`,
    data: {
      type: 'Feature',
      issue: feature.issue
    }
  });

  const style = transform ? {
    transform: `translate3d(${transform.x}px, ${transform.y}px, 0)`,
    opacity: isDragging ? 0.5 : 1,
  } : undefined;

  const handleUserStoryToggle = useCallback((userStoryId) => {
    setUserStoriesExpanded(prev => {
      const newMap = new Map(prev);
      newMap.set(userStoryId, !prev.get(userStoryId));
      return newMap;
    });
  }, []);

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...listeners}
      {...attributes}
      className="feature-card"
      data-feature-id={feature.issue.id}
    >
      <FeatureHeader
        feature={feature}
        expanded={expanded}
        onToggle={onToggle}
      />

      {expanded && (
        <UserStoryList
          userStories={feature.user_stories}
          userStoriesExpanded={userStoriesExpanded}
          onUserStoryToggle={handleUserStoryToggle}
          onUserStoryAdd={onUserStoryAdd}
          onUserStoryUpdate={onUserStoryUpdate}
          onUserStoryDelete={onUserStoryDelete}
        />
      )}
    </div>
  );
};
```

### 3.2 FeatureHeader

```javascript
// assets/javascripts/kanban/components/FeatureHeader.jsx
import React from 'react';

export const FeatureHeader = ({ feature, expanded, onToggle }) => {
  const getStatusColor = (status) => {
    const colors = {
      '進行中': '#fff3e0',
      '完了': '#e0e0e0',
      '未着手': '#f5f5f5'
    };
    return colors[status] || '#f5f5f5';
  };

  return (
    <div className="feature-header">
      <h3
        className="feature-title"
        onClick={onToggle}
        style={{ cursor: 'pointer' }}
      >
        {feature.issue.subject}
      </h3>

      <span
        className="feature-status-badge"
        style={{ backgroundColor: getStatusColor(feature.issue.status) }}
      >
        {feature.issue.status}
      </span>
    </div>
  );
};
```

### 3.3 UserStoryList

```javascript
// assets/javascripts/kanban/components/UserStoryList.jsx
import React from 'react';
import { UserStoryItem } from './UserStoryItem';

export const UserStoryList = ({
  userStories,
  userStoriesExpanded,
  onUserStoryToggle,
  onUserStoryAdd,
  onUserStoryUpdate,
  onUserStoryDelete
}) => {
  return (
    <div className="user-story-list">
      {userStories.map(userStory => (
        <UserStoryItem
          key={userStory.issue.id}
          userStory={userStory}
          expanded={userStoriesExpanded.get(userStory.issue.id) || false}
          onToggle={() => onUserStoryToggle(userStory.issue.id)}
          onUpdate={onUserStoryUpdate}
          onDelete={onUserStoryDelete}
        />
      ))}

      <button
        className="add-user-story-btn"
        onClick={onUserStoryAdd}
      >
        + UserStory
      </button>
    </div>
  );
};
```

### 3.4 UserStoryItem

```javascript
// assets/javascripts/kanban/components/UserStoryItem.jsx
import React from 'react';
import { TaskContainer } from './TaskContainer';
import { TestContainer } from './TestContainer';
import { BugContainer } from './BugContainer';

export const UserStoryItem = ({
  userStory,
  expanded,
  onToggle,
  onUpdate,
  onDelete
}) => {
  const getStatusColor = (status) => {
    const colors = {
      '進行中': '#f0f0f0',
      '完了': '#e0e0e0',
      '未着手': '#f5f5f5'
    };
    return colors[status] || '#f5f5f5';
  };

  const handleDeleteClick = (e) => {
    e.stopPropagation();
    if (window.confirm(`UserStory "${userStory.issue.subject}" を削除しますか？`)) {
      onDelete(userStory.issue.id);
    }
  };

  return (
    <div className={`user-story ${expanded ? 'expanded' : 'collapsed'}`}>
      <div className="user-story-header" onClick={onToggle}>
        <button className="collapse-btn">
          {expanded ? '▼' : '▶'}
        </button>

        <span
          className={`user-story-title ${expanded ? '' : 'collapsed-title'}`}
        >
          {userStory.issue.subject}
        </span>

        <span
          className="user-story-status"
          style={{ backgroundColor: getStatusColor(userStory.issue.status) }}
        >
          {userStory.issue.status}
        </span>

        <button
          className="user-story-delete-btn"
          onClick={handleDeleteClick}
          title="UserStoryを削除"
        >
          Delete
        </button>
      </div>

      {expanded && (
        <>
          <TaskContainer
            tasks={userStory.tasks}
            userStoryId={userStory.issue.id}
            onTaskAdd={() => console.log('Task追加')}
            onTaskUpdate={() => console.log('Task更新')}
            onTaskDelete={() => console.log('Task削除')}
          />

          <TestContainer
            tests={userStory.tests}
            userStoryId={userStory.issue.id}
            onTestAdd={() => console.log('Test追加')}
            onTestUpdate={() => console.log('Test更新')}
            onTestDelete={() => console.log('Test削除')}
          />

          <BugContainer
            bugs={userStory.bugs}
            userStoryId={userStory.issue.id}
            onBugAdd={() => console.log('Bug追加')}
            onBugUpdate={() => console.log('Bug更新')}
            onBugDelete={() => console.log('Bug削除')}
          />
        </>
      )}
    </div>
  );
};
```

## 4. 共通カードコンポーネント

### 4.1 BaseItemCard

```javascript
// assets/javascripts/kanban/components/BaseItemCard.jsx
import React from 'react';

export const BaseItemCard = ({
  item,
  type, // 'Task' | 'Test' | 'Bug'
  onUpdate,
  onDelete,
  className = ''
}) => {
  const getAssigneeDisplay = (assignee) => {
    if (!assignee) return '（未割当）';
    return assignee.name || assignee;
  };

  const handleDeleteClick = (e) => {
    e.stopPropagation();
    if (window.confirm(`${type} "${item.subject}" を削除しますか？`)) {
      onDelete(item.id);
    }
  };

  const getStatusColor = (status) => {
    const colors = {
      '進行中': '#f0f0f0',
      '完了': '#e0e0e0',
      '対応中': '#f0f0f0',
      '未着手': '#f0f0f0'
    };
    return colors[status] || '#f0f0f0';
  };

  return (
    <div className={`base-item-card ${type.toLowerCase()}-card ${className}`}>
      <div className="item-card-content">
        <div className="item-name">{item.subject}</div>
        <div className="item-assignee">
          {getAssigneeDisplay(item.assigned_to)}
        </div>
        <button
          className="item-delete-btn"
          onClick={handleDeleteClick}
          title={`${type}を削除`}
        >
          Delete
        </button>
      </div>

      <div className="item-status-container">
        <span
          className="item-status"
          style={{ backgroundColor: getStatusColor(item.status) }}
        >
          {item.status}
        </span>
      </div>
    </div>
  );
};
```

## 5. コンテナコンポーネント

### 5.1 TaskContainer

```javascript
// assets/javascripts/kanban/components/TaskContainer.jsx
import React from 'react';
import { BaseItemCard } from './BaseItemCard';

export const TaskContainer = ({
  tasks,
  userStoryId,
  onTaskAdd,
  onTaskUpdate,
  onTaskDelete
}) => {
  return (
    <div className="task-container">
      <div className="task-header">
        <span>Task</span>
        <button
          className="add-task-btn"
          onClick={() => onTaskAdd(userStoryId)}
        >
          + Task
        </button>
      </div>

      <div className="task-items">
        {tasks.map(task => (
          <BaseItemCard
            key={task.id}
            item={task}
            type="Task"
            onUpdate={onTaskUpdate}
            onDelete={onTaskDelete}
          />
        ))}
      </div>
    </div>
  );
};
```

### 5.2 TestContainer & BugContainer

```javascript
// TestContainer と BugContainer は TaskContainer と同様の構造
// type プロパティと色設定のみ変更
```

## 6. Ruby-React データ結合

### 6.1 データ構造定義

```ruby
# app/services/kanban/feature_card_data_builder.rb
class Kanban::FeatureCardDataBuilder
  def initialize(feature_issue)
    @feature = feature_issue
  end

  def build
    {
      issue: serialize_issue(@feature),
      user_stories: build_user_stories
    }
  end

  private

  def build_user_stories
    @feature.children.where(tracker: user_story_tracker).map do |user_story|
      {
        issue: serialize_issue(user_story),
        tasks: build_child_items(user_story, 'Task'),
        tests: build_child_items(user_story, 'Test'),
        bugs: build_child_items(user_story, 'Bug')
      }
    end
  end

  def build_child_items(parent, tracker_name)
    parent.children.joins(:tracker)
          .where(trackers: { name: tracker_name })
          .map { |item| serialize_issue(item) }
  end

  def serialize_issue(issue)
    {
      id: issue.id,
      subject: issue.subject,
      status: issue.status.name,
      assigned_to: issue.assigned_to&.name,
      created_on: issue.created_on.iso8601,
      updated_on: issue.updated_on.iso8601
    }
  end

  def user_story_tracker
    Tracker.find_by(name: 'UserStory')
  end
end
```

### 6.2 API Controller 拡張

```ruby
# app/controllers/kanban/feature_cards_controller.rb
class Kanban::FeatureCardsController < ApplicationController
  include KanbanApiConcern

  # GET /kanban/projects/:project_id/feature_cards
  def index
    features = @project.issues.includes(:tracker, :status, :assigned_to)
                      .where(trackers: { name: 'Feature' })
                      .order(:created_on)

    feature_cards = features.map do |feature|
      Kanban::FeatureCardDataBuilder.new(feature).build
    end

    render json: {
      feature_cards: feature_cards,
      metadata: {
        total_features: features.count,
        total_user_stories: count_user_stories(features),
        last_updated: Time.current.iso8601
      }
    }
  end

  # POST /kanban/projects/:project_id/feature_cards/:id/user_stories
  def create_user_story
    feature = @project.issues.find(params[:id])

    user_story = Issue.new(user_story_params)
    user_story.project = @project
    user_story.parent = feature
    user_story.tracker = Tracker.find_by(name: 'UserStory')
    user_story.author = User.current

    if user_story.save
      render json: {
        user_story: serialize_issue(user_story),
        message: 'UserStory作成成功'
      }
    else
      render json: {
        errors: user_story.errors,
        message: 'UserStory作成失敗'
      }, status: :unprocessable_entity
    end
  end

  private

  def user_story_params
    params.require(:user_story).permit(:subject, :description, :assigned_to_id)
  end

  def count_user_stories(features)
    Issue.where(parent: features, tracker: Tracker.find_by(name: 'UserStory')).count
  end
end
```

## 7. CSS スタイリング設計

### 7.1 FeatureCard スタイル

```scss
// assets/stylesheets/kanban/feature_card.scss
.feature-card {
  border: 2px solid #dee2e6;
  background: #f8f9fa;
  border-radius: 4px;
  padding: 8px;
  margin-bottom: 16px;

  .feature-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 10px;

    .feature-title {
      flex: 1;
      font-weight: bold;
      font-size: 12px;
      color: #01579b;
      background: #e1f5fe;
      padding: 5px 10px;
      border-radius: 3px;
      cursor: pointer;
    }

    .feature-status-badge {
      font-size: 9px;
      font-weight: bold;
      color: #ff9800;
      border: 1px solid #ff9800;
      padding: 2px 8px;
      border-radius: 3px;
      margin-left: 10px;
    }
  }
}

.user-story-list {
  background: white;
  border: 1px solid #e0e0e0;
  padding: 10px;

  .user-story {
    border: 1px solid #e0e0e0;
    margin-bottom: 10px;

    &.expanded {
      // 展開時のスタイル
    }

    &.collapsed {
      height: 25px;
      overflow: hidden;

      .user-story-title {
        color: #666666;
        background: #f5f5f5;
      }
    }

    .user-story-header {
      display: flex;
      align-items: center;
      padding: 5px;
      cursor: pointer;

      .collapse-btn {
        width: 15px;
        height: 15px;
        border: 1px solid #e0e0e0;
        background: white;
        font-size: 8px;
        margin-right: 5px;
      }

      .user-story-title {
        flex: 1;
        font-size: 10px;
        padding: 5px;
      }

      .user-story-status {
        font-size: 8px;
        padding: 2px 6px;
        margin-left: 10px;
        border-radius: 2px;
      }

      .user-story-delete-btn {
        font-size: 7px;
        color: #f44336;
        border: 1px dashed #f44336;
        background: #ffebee;
        padding: 1px 4px;
        margin-left: 5px;
      }
    }
  }
}
```

### 7.2 BaseItemCard スタイル

```scss
.base-item-card {
  display: flex;
  align-items: flex-start;
  margin-bottom: 5px;

  .item-card-content {
    width: 160px;
    height: 25px;
    border: 1px solid #d0d0d0;
    background: white;
    padding: 2px 5px;
    display: flex;
    flex-direction: column;

    .item-name {
      font-size: 9px;
      line-height: 12px;
      font-weight: normal;
    }

    .item-assignee {
      font-size: 7px;
      color: #666666;
      line-height: 9px;
    }

    .item-delete-btn {
      position: absolute;
      top: 2px;
      right: 2px;
      font-size: 6px;
      color: #f44336;
      border: 1px dashed #f44336;
      background: #ffebee;
      padding: 1px 3px;
    }
  }

  .item-status-container {
    margin-left: 5px;

    .item-status {
      font-size: 7px;
      padding: 2px 4px;
      border: 1px solid #999999;
      border-radius: 2px;
    }
  }
}

// Task専用スタイル
.task-card .item-card-content {
  .item-delete-btn {
    color: #2196f3;
    border-color: #2196f3;
    background: #e3f2fd;
  }
}

// Test専用スタイル
.test-card .item-card-content {
  .item-delete-btn {
    color: #9c27b0;
    border-color: #9c27b0;
    background: #f3e5f5;
  }
}
```

## 8. テスト設計

### 8.1 React Component テスト

```javascript
// spec/javascript/kanban/components/FeatureCard.test.jsx
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { FeatureCard } from '../../../assets/javascripts/kanban/components/FeatureCard';

const mockFeature = {
  issue: {
    id: 1,
    subject: 'ユーザー登録機能',
    status: '進行中'
  },
  user_stories: [{
    issue: {
      id: 2,
      subject: 'ユーザー登録フォーム',
      status: '進行中'
    },
    tasks: [{
      id: 3,
      subject: 'バリデーション実装',
      status: '進行中',
      assigned_to: '田中太郎'
    }],
    tests: [{
      id: 4,
      subject: '単体テスト作成',
      status: '未着手',
      assigned_to: null
    }],
    bugs: []
  }]
};

describe('FeatureCard', () => {
  it('フィーチャータイトルとステータスが表示される' do
    render(
      <FeatureCard
        feature={mockFeature}
        expanded={true}
        onToggle={() => {}}
      />
    );

    expect(screen.getByText('ユーザー登録機能')).toBeInTheDocument();
    expect(screen.getByText('進行中')).toBeInTheDocument();
  });

  it 'UserStoryの折り畳み/展開ができる' do
    const mockOnToggle = jest.fn();
    render(
      <FeatureCard
        feature={mockFeature}
        expanded={true}
        onToggle={mockOnToggle}
      />
    );

    const collapseButton = screen.getByText('▼');
    fireEvent.click(collapseButton);

    // UserStory内部のonToggleが呼ばれることを確認
    // （実際のテストでは内部コンポーネントのmockが必要）
  });

  it 'Task/Test/Bugの情報が正しく表示される' do
    render(
      <FeatureCard
        feature={mockFeature}
        expanded={true}
        onToggle={() => {}}
      />
    );

    expect(screen.getByText('バリデーション実装')).toBeInTheDocument();
    expect(screen.getByText('田中太郎')).toBeInTheDocument();
    expect(screen.getByText('単体テスト作成')).toBeInTheDocument();
    expect(screen.getByText('（未割当）')).toBeInTheDocument();
  });

  it 'Deleteボタンクリックで確認ダイアログが表示される' do
    window.confirm = jest.fn(() => true);
    const mockOnDelete = jest.fn();

    render(
      <FeatureCard
        feature={mockFeature}
        expanded={true}
        onToggle={() => {}}
        onUserStoryDelete={mockOnDelete}
      />
    );

    const deleteButton = screen.getByText('Delete');
    fireEvent.click(deleteButton);

    expect(window.confirm).toHaveBeenCalled();
  });
});
```

## 9. パフォーマンス最適化

### 9.1 React.memo 活用

```javascript
// コンポーネントのメモ化
export const FeatureCard = React.memo(({ feature, expanded, onToggle, ...props }) => {
  // コンポーネント実装
}, (prevProps, nextProps) => {
  // カスタム比較関数
  return prevProps.feature.issue.updated_on === nextProps.feature.issue.updated_on &&
         prevProps.expanded === nextProps.expanded;
});

export const BaseItemCard = React.memo(({ item, type, onUpdate, onDelete }) => {
  // コンポーネント実装
}, (prevProps, nextProps) => {
  return prevProps.item.id === nextProps.item.id &&
         prevProps.item.updated_on === nextProps.item.updated_on;
});
```

### 9.2 Virtual Scrolling 対応

```javascript
// 大量のFeatureCard表示時の仮想スクロール対応
import { FixedSizeList as List } from 'react-window';

export const FeatureCardList = ({ features }) => {
  const Row = ({ index, style }) => (
    <div style={style}>
      <FeatureCard
        feature={features[index]}
        expanded={expandedStates[features[index].issue.id] || false}
        onToggle={(id) => handleToggle(id)}
      />
    </div>
  );

  return (
    <List
      height={600}
      itemCount={features.length}
      itemSize={200}  // 折り畳み時の概算高さ
    >
      {Row}
    </List>
  );
};
```

---

*ワイヤーフレーム準拠のFeature Cardコンポーネント設計。折り畳み階層構造とRuby-React統合を実現*