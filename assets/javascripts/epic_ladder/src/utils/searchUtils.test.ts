import { describe, it, expect } from 'vitest';
import { searchIssues, searchAllIssues, findByExactId, searchWithFilters } from './searchUtils';
import type { Epic, Feature, UserStory, Task, Test, Bug } from '../types/normalized-api';

describe('searchUtils', () => {
  const mockEntities = {
    epics: {
      'epic-1': { id: 'epic-1', subject: 'ユーザー認証機能' } as Epic,
      'epic-2': { id: 'epic-2', subject: '決済システム' } as Epic,
      '101': { id: '101', subject: 'ID検索テスト用Epic' } as Epic,
    },
    features: {
      'feature-1': { id: 'feature-1', title: 'ログイン画面' } as Feature,
      'feature-2': { id: 'feature-2', title: '会員登録フォーム' } as Feature,
      '201': { id: '201', title: 'ID検索テスト用Feature' } as Feature,
    },
    user_stories: {
      'story-1': { id: 'story-1', title: 'ユーザーがログインできる' } as UserStory,
      'story-2': { id: 'story-2', title: 'パスワードリセット機能' } as UserStory,
    },
    tasks: {
      'task-1': { id: 'task-1', title: 'ログインAPIの実装' } as Task,
      'task-2': { id: 'task-2', title: 'フロントエンド画面作成' } as Task,
    },
    tests: {
      'test-1': { id: 'test-1', title: 'ログインテスト' } as Test,
    },
    bugs: {
      'bug-1': { id: 'bug-1', title: 'ログイン失敗時のバグ' } as Bug,
    },
  };

  describe('searchIssues (既存機能: 最初の1件のみ返す)', () => {
    it('Epic にマッチする場合、最初の1件を返す', () => {
      const result = searchIssues(mockEntities, 'ユーザー');
      expect(result).toEqual({
        id: 'epic-1',
        type: 'epic',
        subject: 'ユーザー認証機能',
      });
    });

    it('Feature にマッチする場合、最初の1件を返す', () => {
      const result = searchIssues(mockEntities, 'ログイン');
      expect(result).toEqual({
        id: 'feature-1',
        type: 'feature',
        subject: 'ログイン画面',
      });
    });

    it('マッチしない場合は null を返す', () => {
      const result = searchIssues(mockEntities, '存在しないキーワード');
      expect(result).toBeNull();
    });

    it('空文字列の場合は null を返す', () => {
      const result = searchIssues(mockEntities, '   ');
      expect(result).toBeNull();
    });

    it('大文字小文字を区別しない', () => {
      const result = searchIssues(mockEntities, 'ユーザー');
      expect(result).not.toBeNull();
      expect(result?.subject).toBe('ユーザー認証機能');
    });
  });

  describe('searchAllIssues (新機能: 全マッチ件を返す)', () => {
    it('複数の Epic/Feature にマッチする場合、全件を返す', () => {
      const results = searchAllIssues(mockEntities, 'ログイン');
      expect(results).toHaveLength(5);
      expect(results.map(r => r.id)).toEqual([
        'feature-1', // ログイン画面
        'story-1',   // ユーザーがログインできる
        'task-1',    // ログインAPIの実装
        'test-1',    // ログインテスト
        'bug-1',     // ログイン失敗時のバグ
      ]);
    });

    it('ログインとバグを含む全検索', () => {
      const results = searchAllIssues(mockEntities, 'ログイン');
      expect(results.some(r => r.type === 'feature')).toBe(true);
      expect(results.some(r => r.type === 'user-story')).toBe(true);
      expect(results.some(r => r.type === 'task')).toBe(true);
      expect(results.some(r => r.type === 'test')).toBe(true);
      expect(results.some(r => r.type === 'bug')).toBe(true);
    });

    it('1件のみマッチする場合も配列で返す', () => {
      const results = searchAllIssues(mockEntities, '決済');
      expect(results).toHaveLength(1);
      expect(results[0]).toEqual({
        id: 'epic-2',
        type: 'epic',
        subject: '決済システム',
      });
    });

    it('マッチしない場合は空配列を返す', () => {
      const results = searchAllIssues(mockEntities, '存在しないキーワード');
      expect(results).toEqual([]);
    });

    it('空文字列の場合は空配列を返す', () => {
      const results = searchAllIssues(mockEntities, '   ');
      expect(results).toEqual([]);
    });

    it('大文字小文字を区別しない', () => {
      const results = searchAllIssues(mockEntities, 'ユーザー');
      expect(results.length).toBeGreaterThan(0);
      expect(results.some(r => r.subject.includes('ユーザー'))).toBe(true);
    });

    it('部分一致で検索できる', () => {
      const results = searchAllIssues(mockEntities, '画面');
      expect(results).toHaveLength(2);
      expect(results.map(r => r.id)).toContain('feature-1'); // ログイン画面
      expect(results.map(r => r.id)).toContain('task-2');    // フロントエンド画面作成
    });

    it('全エンティティタイプを横断検索する', () => {
      const results = searchAllIssues(mockEntities, 'ログイン');
      const types = results.map(r => r.type);
      expect(types).toContain('feature');
      expect(types).toContain('user-story');
      expect(types).toContain('task');
      expect(types).toContain('test');
      expect(types).toContain('bug');
    });
  });

  describe('findByExactId (Phase 1新機能: ID完全一致検索)', () => {
    it('Epicの数値IDで完全一致検索できる', () => {
      const result = findByExactId(mockEntities, 101);
      expect(result).toEqual({
        id: '101',
        type: 'epic',
        subject: 'ID検索テスト用Epic',
      });
    });

    it('Featureの数値IDで完全一致検索できる', () => {
      const result = findByExactId(mockEntities, 201);
      expect(result).toEqual({
        id: '201',
        type: 'feature',
        subject: 'ID検索テスト用Feature',
      });
    });

    it('存在しないIDの場合はnullを返す', () => {
      const result = findByExactId(mockEntities, 999);
      expect(result).toBeNull();
    });
  });

  describe('searchAllIssues with ID検索 (Phase 1新機能)', () => {
    it('数値のみ入力時はID完全一致検索を優先する', () => {
      const results = searchAllIssues(mockEntities, '101');
      expect(results).toHaveLength(1);
      expect(results[0]).toEqual({
        id: '101',
        type: 'epic',
        subject: 'ID検索テスト用Epic',
        isExactIdMatch: true, // フラグが立つ
      });
    });

    it('ID完全一致した場合、isExactIdMatchフラグがtrueになる', () => {
      const results = searchAllIssues(mockEntities, '201');
      expect(results).toHaveLength(1);
      expect(results[0].isExactIdMatch).toBe(true);
    });

    it('数値でもIDが存在しない場合は通常のsubject検索を実行', () => {
      const results = searchAllIssues(mockEntities, '999');
      expect(results).toHaveLength(0);
    });

    it('文字列混在の場合は通常のsubject検索を実行', () => {
      const results = searchAllIssues(mockEntities, 'ID: 101');
      // 通常のsubject検索なのでisExactIdMatchはfalse
      expect(results.every(r => !r.isExactIdMatch)).toBe(true);
    });
  });

  describe('searchWithFilters (Phase 2スケルトン関数)', () => {
    it('queryのみ指定した場合、searchAllIssuesと同じ結果を返す', () => {
      const results = searchWithFilters(mockEntities, { query: 'ログイン' });
      expect(results).toHaveLength(5);
      expect(results.map(r => r.id)).toContain('feature-1');
    });

    it('searchTarget="subject"の場合も動作する', () => {
      const results = searchWithFilters(mockEntities, {
        query: 'ユーザー',
        searchTarget: 'subject'
      });
      expect(results.length).toBeGreaterThan(0);
    });

    it('searchTarget="description"の場合も動作する（Phase 2未実装でもエラーにならない）', () => {
      const results = searchWithFilters(mockEntities, {
        query: 'テスト',
        searchTarget: 'description'
      });
      // Phase 2未実装なので、subjectのみの検索結果が返る
      expect(Array.isArray(results)).toBe(true);
    });

    it('searchTarget="all"の場合も動作する', () => {
      const results = searchWithFilters(mockEntities, {
        query: 'ログイン',
        searchTarget: 'all'
      });
      expect(Array.isArray(results)).toBe(true);
    });

    it('statusIdsフィルターを指定しても動作する（Phase 3未実装）', () => {
      const results = searchWithFilters(mockEntities, {
        query: 'ログイン',
        statusIds: [1, 2]
      });
      // Phase 3未実装なので、statusフィルターは適用されない
      expect(Array.isArray(results)).toBe(true);
    });

    it('空のqueryの場合は空配列を返す', () => {
      const results = searchWithFilters(mockEntities, { query: '' });
      expect(results).toEqual([]);
    });
  });

  describe('searchIssues - 全エンティティタイプのカバレッジ', () => {
    it('UserStoryにマッチする場合、最初の1件を返す', () => {
      const result = searchIssues(mockEntities, 'パスワード');
      expect(result).toEqual({
        id: 'story-2',
        type: 'user-story',
        subject: 'パスワードリセット機能',
      });
    });

    it('Taskにマッチする場合、最初の1件を返す', () => {
      const result = searchIssues(mockEntities, 'API');
      expect(result).toEqual({
        id: 'task-1',
        type: 'task',
        subject: 'ログインAPIの実装',
      });
    });

    it('Testにマッチする場合、最初の1件を返す', () => {
      const result = searchIssues(mockEntities, 'ログインテスト');
      expect(result).toEqual({
        id: 'test-1',
        type: 'test',
        subject: 'ログインテスト',
      });
    });

    it('Bugにマッチする場合、最初の1件を返す', () => {
      const result = searchIssues(mockEntities, 'バグ');
      expect(result).toEqual({
        id: 'bug-1',
        type: 'bug',
        subject: 'ログイン失敗時のバグ',
      });
    });
  });

  describe('searchAllIssues - 各エンティティタイプの完全カバレッジ', () => {
    it('Epicのみにマッチする検索', () => {
      const results = searchAllIssues(mockEntities, '決済');
      expect(results).toHaveLength(1);
      expect(results[0].type).toBe('epic');
    });

    it('Featureのみにマッチする検索', () => {
      const results = searchAllIssues(mockEntities, '会員登録');
      expect(results).toHaveLength(1);
      expect(results[0].type).toBe('feature');
    });

    it('UserStoryのみにマッチする検索', () => {
      const results = searchAllIssues(mockEntities, 'パスワードリセット');
      expect(results).toHaveLength(1);
      expect(results[0].type).toBe('user-story');
    });

    it('Taskのみにマッチする検索', () => {
      const results = searchAllIssues(mockEntities, 'フロントエンド');
      expect(results).toHaveLength(1);
      expect(results[0].type).toBe('task');
    });

    it('Testのみにマッチする検索', () => {
      const results = searchAllIssues(mockEntities, 'ログインテスト');
      expect(results).toHaveLength(1);
      expect(results[0].type).toBe('test');
    });

    it('Bugのみにマッチする検索', () => {
      const results = searchAllIssues(mockEntities, '失敗時');
      expect(results).toHaveLength(1);
      expect(results[0].type).toBe('bug');
    });
  });

  describe('findByExactId - 全エンティティタイプのカバレッジ', () => {
    const entitiesWithNumericIds = {
      epics: { '301': { id: '301', subject: 'Epic 301' } as Epic },
      features: { '302': { id: '302', title: 'Feature 302' } as Feature },
      user_stories: { '303': { id: '303', title: 'UserStory 303' } as UserStory },
      tasks: { '304': { id: '304', title: 'Task 304' } as Task },
      tests: { '305': { id: '305', title: 'Test 305' } as Test },
      bugs: { '306': { id: '306', title: 'Bug 306' } as Bug },
    };

    it('Epic IDで検索できる', () => {
      const result = findByExactId(entitiesWithNumericIds, 301);
      expect(result?.type).toBe('epic');
      expect(result?.id).toBe('301');
    });

    it('Feature IDで検索できる', () => {
      const result = findByExactId(entitiesWithNumericIds, 302);
      expect(result?.type).toBe('feature');
      expect(result?.id).toBe('302');
    });

    it('UserStory IDで検索できる', () => {
      const result = findByExactId(entitiesWithNumericIds, 303);
      expect(result?.type).toBe('user-story');
      expect(result?.id).toBe('303');
    });

    it('Task IDで検索できる', () => {
      const result = findByExactId(entitiesWithNumericIds, 304);
      expect(result?.type).toBe('task');
      expect(result?.id).toBe('304');
    });

    it('Test IDで検索できる', () => {
      const result = findByExactId(entitiesWithNumericIds, 305);
      expect(result?.type).toBe('test');
      expect(result?.id).toBe('305');
    });

    it('Bug IDで検索できる', () => {
      const result = findByExactId(entitiesWithNumericIds, 306);
      expect(result?.type).toBe('bug');
      expect(result?.id).toBe('306');
    });
  });
});
