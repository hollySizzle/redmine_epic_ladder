/**
 * Issue検索ユーティリティ
 *
 * グリッド内の全issueからタイトル（subject）で検索する
 */

import type { Epic, Feature, UserStory, Task, Test, Bug } from '../types/normalized-api';

type SearchableIssue = Epic | Feature | UserStory | Task | Test | Bug;

interface SearchResult {
  id: string;
  type: 'epic' | 'feature' | 'user-story' | 'task' | 'test' | 'bug';
  subject: string;
}

interface Entities {
  epics: Record<string, Epic>;
  features: Record<string, Feature>;
  user_stories: Record<string, UserStory>;
  tasks: Record<string, Task>;
  tests: Record<string, Test>;
  bugs: Record<string, Bug>;
}

/**
 * 全entitiesからタイトルで検索（部分一致、大文字小文字区別なし）
 *
 * @param entities - Zustandストアのentities
 * @param query - 検索クエリ
 * @returns マッチした最初のissue、見つからない場合はnull
 */
export function searchIssues(entities: Entities, query: string): SearchResult | null {
  const normalizedQuery = query.toLowerCase().trim();

  if (!normalizedQuery) return null;

  // Epic検索
  for (const epic of Object.values(entities.epics)) {
    if (epic.subject.toLowerCase().includes(normalizedQuery)) {
      return { id: epic.id, type: 'epic', subject: epic.subject };
    }
  }

  // Feature検索
  for (const feature of Object.values(entities.features)) {
    if (feature.title.toLowerCase().includes(normalizedQuery)) {
      return { id: feature.id, type: 'feature', subject: feature.title };
    }
  }

  // UserStory検索
  for (const story of Object.values(entities.user_stories)) {
    if (story.title.toLowerCase().includes(normalizedQuery)) {
      return { id: story.id, type: 'user-story', subject: story.title };
    }
  }

  // Task検索
  for (const task of Object.values(entities.tasks)) {
    if (task.title.toLowerCase().includes(normalizedQuery)) {
      return { id: task.id, type: 'task', subject: task.title };
    }
  }

  // Test検索
  for (const test of Object.values(entities.tests)) {
    if (test.title.toLowerCase().includes(normalizedQuery)) {
      return { id: test.id, type: 'test', subject: test.title };
    }
  }

  // Bug検索
  for (const bug of Object.values(entities.bugs)) {
    if (bug.title.toLowerCase().includes(normalizedQuery)) {
      return { id: bug.id, type: 'bug', subject: bug.title };
    }
  }

  return null;
}

/**
 * 全entitiesからタイトルで検索し、マッチした全てのissueを返す（部分一致、大文字小文字区別なし）
 *
 * @param entities - Zustandストアのentities
 * @param query - 検索クエリ
 * @returns マッチした全てのissue配列（見つからない場合は空配列）
 */
export function searchAllIssues(entities: Entities, query: string): SearchResult[] {
  const normalizedQuery = query.toLowerCase().trim();

  if (!normalizedQuery) return [];

  const results: SearchResult[] = [];

  // Epic検索
  for (const epic of Object.values(entities.epics)) {
    if (epic.subject.toLowerCase().includes(normalizedQuery)) {
      results.push({ id: epic.id, type: 'epic', subject: epic.subject });
    }
  }

  // Feature検索
  for (const feature of Object.values(entities.features)) {
    if (feature.title.toLowerCase().includes(normalizedQuery)) {
      results.push({ id: feature.id, type: 'feature', subject: feature.title });
    }
  }

  // UserStory検索
  for (const story of Object.values(entities.user_stories)) {
    if (story.title.toLowerCase().includes(normalizedQuery)) {
      results.push({ id: story.id, type: 'user-story', subject: story.title });
    }
  }

  // Task検索
  for (const task of Object.values(entities.tasks)) {
    if (task.title.toLowerCase().includes(normalizedQuery)) {
      results.push({ id: task.id, type: 'task', subject: task.title });
    }
  }

  // Test検索
  for (const test of Object.values(entities.tests)) {
    if (test.title.toLowerCase().includes(normalizedQuery)) {
      results.push({ id: test.id, type: 'test', subject: test.title });
    }
  }

  // Bug検索
  for (const bug of Object.values(entities.bugs)) {
    if (bug.title.toLowerCase().includes(normalizedQuery)) {
      results.push({ id: bug.id, type: 'bug', subject: bug.title });
    }
  }

  return results;
}
