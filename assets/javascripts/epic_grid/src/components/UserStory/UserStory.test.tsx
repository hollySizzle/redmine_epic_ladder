import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { UserStory } from './UserStory';
import { useStore } from '../../store/useStore';

describe('UserStory - Collapse Functionality', () => {
  beforeEach(() => {
    // ストアを初期状態にリセット
    useStore.setState({
      entities: {
        epics: {},
        versions: {},
        features: {},
        user_stories: {
          us1: {
            id: 'us1',
            title: 'Test User Story',
            description: '',
            status: 'open',
            parent_feature_id: 'f1',
            task_ids: ['t1'],
            test_ids: ['test1'],
            bug_ids: ['b1'],
            fixed_version_id: null,
            version_source: 'none',
            assigned_to_id: null,
            start_date: null,
            due_date: null,
            statistics: {
              total_tasks: 1,
              total_tests: 1,
              total_bugs: 1,
              completed_tasks: 0,
              completed_tests: 0,
              completed_bugs: 0
            },
            created_on: '2025-01-01',
            updated_on: '2025-01-01'
          }
        },
        tasks: {
          t1: { id: 't1', title: 'Task 1', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null }
        },
        tests: {
          test1: { id: 'test1', title: 'Test 1', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null }
        },
        bugs: {
          b1: { id: 'b1', title: 'Bug 1', status: 'open', parent_user_story_id: 'us1', fixed_version_id: null }
        },
        users: {}
      },
      grid: { index: {}, epic_order: [], feature_order_by_epic: {}, version_order: [] },
      isLoading: false,
      error: null,
      projectId: 'project1',
      userStoryCollapseStates: {},
      isAssignedToVisible: false,
      isDueDateVisible: false,
      isIssueIdVisible: true,
      isUnassignedHighlightVisible: true
    });
  });

  describe('Rendering', () => {
    it('should render user story with collapse toggle button', () => {
      render(<UserStory storyId="us1" />);

      expect(screen.getByText('Test User Story')).toBeTruthy();

      // 折り畳みボタンがある
      const toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');
      expect(toggleButton).toBeTruthy();
    });

    it('should show ▼ icon when expanded', () => {
      render(<UserStory storyId="us1" />);

      const toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');
      expect(toggleButton.textContent).toBe('▼');
    });

    it('should show ▶ icon when collapsed', async () => {
      const user = userEvent.setup();

      render(<UserStory storyId="us1" />);

      const toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');

      // クリックして折り畳み
      await user.click(toggleButton);

      // アイコンが変わる
      const collapsedButton = screen.getByTitle('Task/Test/Bug配下を展開');
      expect(collapsedButton.textContent).toBe('▶');
    });
  });

  describe('Interaction', () => {
    it('should toggle own collapse state when button clicked', async () => {
      const user = userEvent.setup();

      render(<UserStory storyId="us1" />);

      // 初期状態: 展開中
      let toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');
      expect(toggleButton.textContent).toBe('▼');

      // クリック: 折り畳み
      await user.click(toggleButton);
      toggleButton = screen.getByTitle('Task/Test/Bug配下を展開');
      expect(toggleButton.textContent).toBe('▶');

      // もう一度クリック: 展開
      await user.click(toggleButton);
      toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');
      expect(toggleButton.textContent).toBe('▼');
    });

    it('should not propagate click to header when toggle clicked', async () => {
      const user = userEvent.setup();

      render(<UserStory storyId="us1" />);

      const toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');

      // トグルボタンをクリック
      await user.click(toggleButton);

      // selectedIssueIdは設定されない（stopPropagationが効いている）
      expect(useStore.getState().selectedIssueId).toBeNull();
    });

    it('should set selectedIssueId when header (not toggle) is clicked', async () => {
      const user = userEvent.setup();

      render(<UserStory storyId="us1" />);

      const header = screen.getByText('Test User Story');

      // ヘッダーをクリック
      await user.click(header);

      // selectedIssueIdが設定される
      expect(useStore.getState().selectedIssueId).toBe('us1');
    });
  });

  describe('TaskTestBugGrid Integration', () => {
    it('should display child items initially', () => {
      render(<UserStory storyId="us1" />);

      // 子要素が表示されている
      expect(screen.getByText('Task 1')).toBeTruthy();
      expect(screen.getByText('Test 1')).toBeTruthy();
      expect(screen.getByText('Bug 1')).toBeTruthy();
    });

    it('should hide child items when collapsed', async () => {
      const user = userEvent.setup();

      render(<UserStory storyId="us1" />);

      const toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');

      // クリックして折り畳み
      await user.click(toggleButton);

      // TaskTestBugGridがnullを返すので、子要素が見えなくなる
      expect(screen.queryByText('Task 1')).toBeNull();
      expect(screen.queryByText('Test 1')).toBeNull();
      expect(screen.queryByText('Bug 1')).toBeNull();
    });
  });


  describe('State Persistence', () => {
    it('should persist own collapse state in store (maintained on remount)', async () => {
      const user = userEvent.setup();

      const { unmount } = render(<UserStory storyId="us1" />);

      // 折り畳む
      const toggleButton = screen.getByTitle('Task/Test/Bug配下を折り畳み');
      await user.click(toggleButton);

      // 確認: 折り畳まれている
      expect(screen.getByTitle('Task/Test/Bug配下を展開')).toBeTruthy();

      // アンマウント
      unmount();

      // 再マウント
      render(<UserStory storyId="us1" />);

      // 折り畳み状態が維持されている（ストアで管理）
      expect(screen.getByTitle('Task/Test/Bug配下を展開')).toBeTruthy();
      expect(screen.queryByText('Task 1')).toBeNull();
    });
  });

  describe('Edge Cases', () => {
    it('should render toggle button even with no children', () => {
      // 子要素がないUserStoryを作成
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us2: {
              id: 'us2',
              title: 'Empty User Story',
              description: '',
              status: 'open',
              parent_feature_id: 'f1',
              task_ids: [],
              test_ids: [],
              bug_ids: [],
              fixed_version_id: null,
              version_source: 'none',
              assigned_to_id: null,
              start_date: null,
              due_date: null,
              statistics: {
                total_tasks: 0,
                total_tests: 0,
                total_bugs: 0,
                completed_tasks: 0,
                completed_tests: 0,
                completed_bugs: 0
              },
              created_on: '2025-01-01',
              updated_on: '2025-01-01'
            }
          }
        }
      });

      render(<UserStory storyId="us2" />);

      // ボタンは表示される
      expect(screen.getByTitle('Task/Test/Bug配下を折り畳み')).toBeTruthy();
    });

    it('should handle closed status correctly', () => {
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us1: {
              ...useStore.getState().entities.user_stories.us1,
              status: 'closed'
            }
          }
        }
      });

      const { container } = render(<UserStory storyId="us1" />);

      // closedクラスが付与される
      const userStoryDiv = container.querySelector('.user-story.closed');
      expect(userStoryDiv).toBeTruthy();
    });
  });

  describe('Overdue Highlighting', () => {
    beforeEach(() => {
      // テスト用の現在日付を固定（2025-10-18）
      vi.setSystemTime(new Date('2025-10-18T12:00:00Z'));
    });

    it('should add overdue class when user story itself is overdue', () => {
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us1: {
              ...useStore.getState().entities.user_stories.us1,
              due_date: '2025-10-17' // 昨日
            }
          },
          tasks: {
            t1: {
              id: 't1',
              title: 'Task 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: null
            }
          },
          tests: {
            test1: {
              id: 'test1',
              title: 'Test 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: null
            }
          },
          bugs: {
            b1: {
              id: 'b1',
              title: 'Bug 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: null
            }
          }
        }
      });

      const { container } = render(<UserStory storyId="us1" />);

      // overdueクラスが付与される
      const userStoryDiv = container.querySelector('.user-story.overdue');
      expect(userStoryDiv).toBeTruthy();
    });

    it('should add overdue class when a child task is overdue', () => {
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us1: {
              ...useStore.getState().entities.user_stories.us1,
              due_date: '2025-12-31' // 未来
            }
          },
          tasks: {
            t1: {
              id: 't1',
              title: 'Task 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: '2025-10-17' // 昨日（期日超過）
            }
          },
          tests: {
            test1: {
              id: 'test1',
              title: 'Test 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: null
            }
          },
          bugs: {
            b1: {
              id: 'b1',
              title: 'Bug 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: null
            }
          }
        }
      });

      const { container } = render(<UserStory storyId="us1" />);

      // 子タスクが期日超過なのでoverdueクラスが付与される
      const userStoryDiv = container.querySelector('.user-story.overdue');
      expect(userStoryDiv).toBeTruthy();
    });

    it('should add overdue class when a child test is overdue', () => {
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us1: {
              ...useStore.getState().entities.user_stories.us1,
              due_date: null
            }
          },
          tasks: {
            t1: {
              id: 't1',
              title: 'Task 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: null
            }
          },
          tests: {
            test1: {
              id: 'test1',
              title: 'Test 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: '2025-10-01' // 期日超過
            }
          },
          bugs: {
            b1: {
              id: 'b1',
              title: 'Bug 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: null
            }
          }
        }
      });

      const { container } = render(<UserStory storyId="us1" />);

      // 子テストが期日超過なのでoverdueクラスが付与される
      const userStoryDiv = container.querySelector('.user-story.overdue');
      expect(userStoryDiv).toBeTruthy();
    });

    it('should add overdue class when a child bug is overdue', () => {
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us1: {
              ...useStore.getState().entities.user_stories.us1,
              due_date: null
            }
          },
          tasks: {
            t1: {
              id: 't1',
              title: 'Task 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: null
            }
          },
          tests: {
            test1: {
              id: 'test1',
              title: 'Test 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: null
            }
          },
          bugs: {
            b1: {
              id: 'b1',
              title: 'Bug 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: '2024-12-31' // 期日超過
            }
          }
        }
      });

      const { container } = render(<UserStory storyId="us1" />);

      // 子バグが期日超過なのでoverdueクラスが付与される
      const userStoryDiv = container.querySelector('.user-story.overdue');
      expect(userStoryDiv).toBeTruthy();
    });

    it('should not add overdue class when all dates are in the future', () => {
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us1: {
              ...useStore.getState().entities.user_stories.us1,
              due_date: '2025-12-31'
            }
          },
          tasks: {
            t1: {
              id: 't1',
              title: 'Task 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: '2025-11-30'
            }
          },
          tests: {
            test1: {
              id: 'test1',
              title: 'Test 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: '2025-11-15'
            }
          },
          bugs: {
            b1: {
              id: 'b1',
              title: 'Bug 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              due_date: '2025-10-31'
            }
          }
        }
      });

      const { container } = render(<UserStory storyId="us1" />);

      // すべて未来の日付なのでoverdueクラスは付与されない
      const userStoryDiv = container.querySelector('.user-story.overdue');
      expect(userStoryDiv).toBeNull();
    });

    it('should not add overdue class when all dates are null', () => {
      const { container } = render(<UserStory storyId="us1" />);

      // 期日が設定されていないのでoverdueクラスは付与されない
      const userStoryDiv = container.querySelector('.user-story.overdue');
      expect(userStoryDiv).toBeNull();
    });
  });

  describe('Unassigned Highlighting', () => {
    it('should add unassigned class when user story itself is unassigned', () => {
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us1: {
              ...useStore.getState().entities.user_stories.us1,
              assigned_to_id: undefined
            }
          },
          tasks: {
            t1: {
              id: 't1',
              title: 'Task 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 1
            }
          },
          tests: {
            test1: {
              id: 'test1',
              title: 'Test 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 1
            }
          },
          bugs: {
            b1: {
              id: 'b1',
              title: 'Bug 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 1
            }
          }
        }
      });

      const { container } = render(<UserStory storyId="us1" />);

      // unassignedクラスが付与される
      const userStoryDiv = container.querySelector('.user-story.unassigned');
      expect(userStoryDiv).toBeTruthy();
    });

    it('should add unassigned class when a child task is unassigned', () => {
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us1: {
              ...useStore.getState().entities.user_stories.us1,
              assigned_to_id: 1
            }
          },
          tasks: {
            t1: {
              id: 't1',
              title: 'Task 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: undefined
            }
          },
          tests: {
            test1: {
              id: 'test1',
              title: 'Test 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 1
            }
          },
          bugs: {
            b1: {
              id: 'b1',
              title: 'Bug 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 1
            }
          }
        }
      });

      const { container } = render(<UserStory storyId="us1" />);

      // 子タスクが担当者不在なのでunassignedクラスが付与される
      const userStoryDiv = container.querySelector('.user-story.unassigned');
      expect(userStoryDiv).toBeTruthy();
    });

    it('should add unassigned class when a child test is unassigned', () => {
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us1: {
              ...useStore.getState().entities.user_stories.us1,
              assigned_to_id: 1
            }
          },
          tasks: {
            t1: {
              id: 't1',
              title: 'Task 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 1
            }
          },
          tests: {
            test1: {
              id: 'test1',
              title: 'Test 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: undefined
            }
          },
          bugs: {
            b1: {
              id: 'b1',
              title: 'Bug 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 1
            }
          }
        }
      });

      const { container } = render(<UserStory storyId="us1" />);

      // 子テストが担当者不在なのでunassignedクラスが付与される
      const userStoryDiv = container.querySelector('.user-story.unassigned');
      expect(userStoryDiv).toBeTruthy();
    });

    it('should add unassigned class when a child bug is unassigned', () => {
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us1: {
              ...useStore.getState().entities.user_stories.us1,
              assigned_to_id: 1
            }
          },
          tasks: {
            t1: {
              id: 't1',
              title: 'Task 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 1
            }
          },
          tests: {
            test1: {
              id: 'test1',
              title: 'Test 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 1
            }
          },
          bugs: {
            b1: {
              id: 'b1',
              title: 'Bug 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: undefined
            }
          }
        }
      });

      const { container } = render(<UserStory storyId="us1" />);

      // 子バグが担当者不在なのでunassignedクラスが付与される
      const userStoryDiv = container.querySelector('.user-story.unassigned');
      expect(userStoryDiv).toBeTruthy();
    });

    it('should not add unassigned class when all items are assigned', () => {
      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us1: {
              ...useStore.getState().entities.user_stories.us1,
              assigned_to_id: 1
            }
          },
          tasks: {
            t1: {
              id: 't1',
              title: 'Task 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 2
            }
          },
          tests: {
            test1: {
              id: 'test1',
              title: 'Test 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 3
            }
          },
          bugs: {
            b1: {
              id: 'b1',
              title: 'Bug 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 4
            }
          }
        }
      });

      const { container } = render(<UserStory storyId="us1" />);

      // すべて担当者が設定されているのでunassignedクラスは付与されない
      const userStoryDiv = container.querySelector('.user-story.unassigned');
      expect(userStoryDiv).toBeNull();
    });

    it('should add both overdue and unassigned classes when both conditions are met', () => {
      vi.setSystemTime(new Date('2025-10-18T12:00:00Z'));

      useStore.setState({
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us1: {
              ...useStore.getState().entities.user_stories.us1,
              due_date: '2025-10-17', // 期日超過
              assigned_to_id: undefined // 担当者不在
            }
          },
          tasks: {
            t1: {
              id: 't1',
              title: 'Task 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 1,
              due_date: null
            }
          },
          tests: {
            test1: {
              id: 'test1',
              title: 'Test 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 1,
              due_date: null
            }
          },
          bugs: {
            b1: {
              id: 'b1',
              title: 'Bug 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 1,
              due_date: null
            }
          }
        }
      });

      const { container } = render(<UserStory storyId="us1" />);

      // 両方のクラスが付与される
      const userStoryDiv = container.querySelector('.user-story.overdue.unassigned');
      expect(userStoryDiv).toBeTruthy();
    });

    it('should NOT add unassigned class when toggle is OFF even if unassigned', () => {
      useStore.setState({
        isUnassignedHighlightVisible: false, // トグルOFF
        entities: {
          ...useStore.getState().entities,
          user_stories: {
            us1: {
              ...useStore.getState().entities.user_stories.us1,
              assigned_to_id: undefined // 担当者不在
            }
          },
          tasks: {
            t1: {
              id: 't1',
              title: 'Task 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: undefined // 子タスクも担当者不在
            }
          },
          tests: {
            test1: {
              id: 'test1',
              title: 'Test 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 1
            }
          },
          bugs: {
            b1: {
              id: 'b1',
              title: 'Bug 1',
              status: 'open',
              parent_user_story_id: 'us1',
              fixed_version_id: null,
              assigned_to_id: 1
            }
          }
        }
      });

      const { container } = render(<UserStory storyId="us1" />);

      // トグルがOFFなのでunassignedクラスは付与されない
      const userStoryDiv = container.querySelector('.user-story.unassigned');
      expect(userStoryDiv).toBeNull();
    });
  });
});
