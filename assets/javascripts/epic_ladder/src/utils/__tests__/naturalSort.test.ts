import { describe, it, expect } from 'vitest';
import { naturalSortKey, compareNaturalSort } from '../naturalSort';

describe('naturalSortKey', () => {
  it('should split string into numeric and non-numeric parts', () => {
    const key = naturalSortKey('10_サーバ構築');
    expect(key).toEqual([
      [0, 10],              // 数値部分
      [1, '_サーバ構築']     // 文字列部分
    ]);
  });

  it('should handle multiple numeric parts', () => {
    const key = naturalSortKey('10_test_20_final');
    expect(key).toEqual([
      [0, 10],
      [1, '_test_'],
      [0, 20],
      [1, '_final']
    ]);
  });

  it('should handle string without numbers', () => {
    const key = naturalSortKey('Apple');
    expect(key).toEqual([
      [1, 'Apple']
    ]);
  });

  it('should handle number-only string', () => {
    const key = naturalSortKey('12345');
    expect(key).toEqual([
      [0, 12345]
    ]);
  });

  it('should handle empty string', () => {
    const key = naturalSortKey('');
    expect(key).toEqual([]);
  });

  it('should parse Japanese characters with numbers', () => {
    const key = naturalSortKey('100_ユーザ管理');
    expect(key).toEqual([
      [0, 100],
      [1, '_ユーザ管理']
    ]);
  });

  it('should handle complex patterns', () => {
    const key = naturalSortKey('1000_出力管理_v2');
    expect(key).toEqual([
      [0, 1000],
      [1, '_出力管理_v'],
      [0, 2]
    ]);
  });
});

describe('compareNaturalSort', () => {
  it('should sort numeric prefixes in natural order', () => {
    const subjects = [
      '100_ユーザ管理',
      '10_サーバ構築',
      '1000_出力管理',
      '2_認証機能'
    ];

    const keys = subjects.map(naturalSortKey);
    keys.sort(compareNaturalSort);

    // ソート後、元の文字列に戻す（検証用）
    const sortedSubjects = subjects
      .map(s => ({ original: s, key: naturalSortKey(s) }))
      .sort((a, b) => compareNaturalSort(a.key, b.key))
      .map(item => item.original);

    expect(sortedSubjects).toEqual([
      '2_認証機能',
      '10_サーバ構築',
      '100_ユーザ管理',
      '1000_出力管理'
    ]);
  });

  it('should prioritize numbers over strings', () => {
    const subjects = ['z_test', '1_test', 'a_test'];
    const sortedSubjects = subjects
      .map(s => ({ original: s, key: naturalSortKey(s) }))
      .sort((a, b) => compareNaturalSort(a.key, b.key))
      .map(item => item.original);

    // 数値プレフィックスが文字列プレフィックスより優先される
    expect(sortedSubjects[0]).toBe('1_test');
  });

  it('should handle same numeric prefix with different suffixes', () => {
    const subjects = ['10_ZZZ', '10_AAA', '10_サーバ構築'];
    const sortedSubjects = subjects
      .map(s => ({ original: s, key: naturalSortKey(s) }))
      .sort((a, b) => compareNaturalSort(a.key, b.key))
      .map(item => item.original);

    // 同じ数値プレフィックスの場合、文字列部分で辞書順ソート
    expect(sortedSubjects).toEqual([
      '10_AAA',
      '10_ZZZ',
      '10_サーバ構築'
    ]);
  });

  it('should compare equal keys', () => {
    const keyA = naturalSortKey('10_test');
    const keyB = naturalSortKey('10_test');

    expect(compareNaturalSort(keyA, keyB)).toBe(0);
  });

  it('should handle keys with different lengths', () => {
    const keyA = naturalSortKey('10');
    const keyB = naturalSortKey('10_suffix');

    // keyAの方が短いので、負の値を返す
    expect(compareNaturalSort(keyA, keyB)).toBeLessThan(0);
  });

  it('should sort real-world Japanese examples correctly', () => {
    const subjects = [
      '100_権限管理',
      '10_AAA',
      '10_ZZZ',
      '10_サーバ構築',
      '2_認証機能',
      '1000_出力管理',
      '100_ユーザ管理'
    ];

    const sortedSubjects = subjects
      .map(s => ({ original: s, key: naturalSortKey(s) }))
      .sort((a, b) => compareNaturalSort(a.key, b.key))
      .map(item => item.original);

    expect(sortedSubjects).toEqual([
      '2_認証機能',
      '10_AAA',
      '10_ZZZ',
      '10_サーバ構築',
      '100_ユーザ管理',
      '100_権限管理',
      '1000_出力管理'
    ]);
  });

  describe('Edge cases', () => {
    it('should handle empty arrays', () => {
      const keyA: Array<[number, number | string]> = [];
      const keyB: Array<[number, number | string]> = [];

      expect(compareNaturalSort(keyA, keyB)).toBe(0);
    });

    it('should handle one empty array', () => {
      const keyA: Array<[number, number | string]> = [];
      const keyB = naturalSortKey('test');

      expect(compareNaturalSort(keyA, keyB)).toBeLessThan(0);
    });

    it('should handle very large numbers', () => {
      const subjects = ['999999_test', '1000000_test', '10_test'];
      const sortedSubjects = subjects
        .map(s => ({ original: s, key: naturalSortKey(s) }))
        .sort((a, b) => compareNaturalSort(a.key, b.key))
        .map(item => item.original);

      expect(sortedSubjects).toEqual([
        '10_test',
        '999999_test',
        '1000000_test'
      ]);
    });
  });

  describe('Integration with Array.sort', () => {
    it('should work as a direct comparator for sort()', () => {
      const items = [
        { id: 'e3', subject: '100_ユーザ管理' },
        { id: 'e1', subject: '10_サーバ構築' },
        { id: 'e4', subject: '1000_出力管理' },
        { id: 'e2', subject: '2_認証機能' }
      ];

      const sorted = items.sort((a, b) => {
        const keyA = naturalSortKey(a.subject);
        const keyB = naturalSortKey(b.subject);
        return compareNaturalSort(keyA, keyB);
      });

      expect(sorted.map(item => item.subject)).toEqual([
        '2_認証機能',
        '10_サーバ構築',
        '100_ユーザ管理',
        '1000_出力管理'
      ]);

      expect(sorted.map(item => item.id)).toEqual(['e2', 'e1', 'e3', 'e4']);
    });
  });
});
