import { useMemo } from 'react';
import { useStore } from '../store/useStore';
import type { EpicData, VersionData, EpicVersionCellData } from '../components/EpicVersion/EpicVersionGrid';
import type { FeatureCardData } from '../components/Feature/FeatureCard';
import type { UserStoryData } from '../components/UserStory/UserStory';
import type { TaskData } from '../components/Task/TaskItem';
import type { TestData } from '../components/Test/TestItem';
import type { BugData } from '../components/Bug/BugItem';

/**
 * 正規化APIデータをコンポーネント用のビューモデルに変換するカスタムフック
 */
export function useGridData() {
  const entities = useStore(state => state.entities);
  const grid = useStore(state => state.grid);
  const isLoading = useStore(state => state.isLoading);
  const error = useStore(state => state.error);

  // Epic一覧を変換
  const epics: EpicData[] = useMemo(() => {
    return grid.epic_order.map(epicId => {
      const epic = entities.epics[epicId];
      return {
        id: epic.id,
        name: epic.subject
      };
    });
  }, [entities.epics, grid.epic_order]);

  // Version一覧を変換
  const versions: VersionData[] = useMemo(() => {
    return grid.version_order
      .filter(versionId => versionId !== 'none')
      .map(versionId => {
        const version = entities.versions[versionId];
        return {
          id: version.id,
          name: version.name
        };
      });
  }, [entities.versions, grid.version_order]);

  // セルデータを変換
  const cells: EpicVersionCellData[] = useMemo(() => {
    const result: EpicVersionCellData[] = [];

    grid.epic_order.forEach(epicId => {
      grid.version_order.forEach(versionId => {
        const cellKey = `${epicId}:${versionId}`;
        const featureIds = grid.index[cellKey] || [];

        const features: FeatureCardData[] = featureIds.map(featureId => {
          const feature = entities.features[featureId];

          // UserStoryデータを変換
          const stories: UserStoryData[] = feature.user_story_ids.map(storyId => {
            const story = entities.user_stories[storyId];

            // Task/Test/Bugデータを変換
            const tasks: TaskData[] = story.task_ids.map(taskId => {
              const task = entities.tasks[taskId];
              return {
                id: task.id,
                name: task.title,
                status: task.status
              };
            });

            const tests: TestData[] = story.test_ids.map(testId => {
              const test = entities.tests[testId];
              return {
                id: test.id,
                name: test.title,
                status: test.status
              };
            });

            const bugs: BugData[] = story.bug_ids.map(bugId => {
              const bug = entities.bugs[bugId];
              return {
                id: bug.id,
                name: bug.title,
                status: bug.status
              };
            });

            return {
              id: story.id,
              title: story.title,
              status: story.status,
              expanded: story.expansion_state,
              tasks,
              tests,
              bugs
            };
          });

          return {
            id: feature.id,
            title: feature.title,
            status: feature.status,
            stories
          };
        });

        result.push({
          epicId,
          versionId: versionId === 'none' ? 'none' : versionId,
          features
        });
      });
    });

    return result;
  }, [entities, grid]);

  return {
    epics,
    versions,
    cells,
    isLoading,
    error
  };
}
