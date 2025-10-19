import { describe, it, expect } from 'vitest';
import { searchIssues, searchAllIssues } from './searchUtils';
import type { Epic, Feature, UserStory, Task, Test, Bug } from '../types/normalized-api';

describe('searchUtils', () => {
  const mockEntities = {
    epics: {
      'epic-1': { id: 'epic-1', subject: 'ユーザー認証機能' } as Epic,
      'epic-2': { id: 'epic-2', subject: '決済システム' } as Epic,
    },
    features: {
      'feature-1': { id: 'feature-1', title: 'ログイン画面' } as Feature,
      'feature-2': { id: 'feature-2', title: '会員登録フォーム' } as Feature,
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
});
