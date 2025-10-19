/**
 * Issue検索ユーティリティ
 *
 * グリッド内の全issueからタイトル（subject）で検索する
 * Phase 1: ID検索対応
 * Phase 2: Description検索対応（スケルトン）
 * Phase 3: ステータスフィルター対応（スケルトン）
 */

import type { Epic, Feature, UserStory, Task, Test, Bug, SearchFilters, SearchResult, SearchTarget } from '../types/normalized-api';

type SearchableIssue = Epic | Feature | UserStory | Task | Test | Bug;

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
 * 【Phase 1対応】数値のみ入力時はID完全一致検索を優先
 *
 * @param entities - Zustandストアのentities
 * @param query - 検索クエリ
 * @returns マッチした全てのissue配列（見つからない場合は空配列）
 */
export function searchAllIssues(entities: Entities, query: string): SearchResult[] {
  const normalizedQuery = query.toLowerCase().trim();

  if (!normalizedQuery) return [];

  // Phase 1: ID完全一致検索（数値のみの場合）
  if (/^\d+$/.test(normalizedQuery)) {
    const exactMatch = findByExactId(entities, parseInt(normalizedQuery, 10));
    if (exactMatch) {
      return [{ ...exactMatch, isExactIdMatch: true }];
    }
  }

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

/**
 * ID完全一致で検索（数値IDのみ）
 *
 * @param entities - Zustandストアのentities
 * @param id - 検索するID（数値）
 * @returns マッチしたissue、見つからない場合はnull
 */
export function findByExactId(entities: Entities, id: number): SearchResult | null {
  const idStr = id.toString();

  // Epic検索
  if (entities.epics[idStr]) {
    const epic = entities.epics[idStr];
    return { id: epic.id, type: 'epic', subject: epic.subject };
  }

  // Feature検索
  if (entities.features[idStr]) {
    const feature = entities.features[idStr];
    return { id: feature.id, type: 'feature', subject: feature.title };
  }

  // UserStory検索
  if (entities.user_stories[idStr]) {
    const story = entities.user_stories[idStr];
    return { id: story.id, type: 'user-story', subject: story.title };
  }

  // Task検索
  if (entities.tasks[idStr]) {
    const task = entities.tasks[idStr];
    return { id: task.id, type: 'task', subject: task.title };
  }

  // Test検索
  if (entities.tests[idStr]) {
    const test = entities.tests[idStr];
    return { id: test.id, type: 'test', subject: test.title };
  }

  // Bug検索
  if (entities.bugs[idStr]) {
    const bug = entities.bugs[idStr];
    return { id: bug.id, type: 'bug', subject: bug.title };
  }

  return null;
}

// ========================================
// Phase 2: Description検索対応（スケルトン）
// ========================================

/**
 * 【Phase 2実装予定】フィルター付き検索
 *
 * @param entities - Zustandストアのentities
 * @param filters - 検索フィルター（query, searchTarget, statusIdsなど）
 * @returns マッチした全てのissue配列
 */
export function searchWithFilters(entities: Entities, filters: SearchFilters): SearchResult[] {
  // TODO: Phase 2で実装
  // - searchTarget が 'description' の場合、descriptionフィールドも検索
  // - searchTarget が 'all' の場合、subject + description を検索

  // 現状は従来のsubject検索のみ（Phase 1互換）
  return searchAllIssues(entities, filters.query);
}

/**
 * 【Phase 2実装予定】検索対象に応じたマッチング判定
 *
 * @param issue - 検索対象のissue
 * @param query - 検索クエリ
 * @param target - 検索対象（subject/description/all）
 * @returns マッチした場合true
 */
function matchesTarget(
  issue: { subject: string; description?: string },
  query: string,
  target: SearchTarget
): boolean {
  // TODO: Phase 2で実装
  switch (target) {
    case 'subject':
      return issue.subject.toLowerCase().includes(query);
    case 'description':
      return (issue.description?.toLowerCase().includes(query) ?? false);
    case 'all':
      return issue.subject.toLowerCase().includes(query) ||
             (issue.description?.toLowerCase().includes(query) ?? false);
  }
}

// ========================================
// Phase 3: ステータスフィルター対応（スケルトン）
// ========================================

/**
 * 【Phase 3実装予定】ステータスフィルター適用
 *
 * @param results - 検索結果
 * @param statusIds - フィルター対象のステータスID配列
 * @returns フィルター適用後の結果
 */
function applyStatusFilter(results: SearchResult[], statusIds: number[]): SearchResult[] {
  // TODO: Phase 3で実装
  // entities から各issueのステータスを取得してフィルタリング
  return results;
}
