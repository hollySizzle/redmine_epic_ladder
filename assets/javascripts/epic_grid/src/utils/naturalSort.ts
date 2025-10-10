/**
 * 自然順ソートキー生成（Ruby実装と同等）
 * 文字列を数値部分と非数値部分に分割し、比較可能な形式に変換
 *
 * @example
 * naturalSortKey("10_サーバ構築") // => [[0, 10], [1, "_サーバ構築"]]
 * naturalSortKey("10_test_20_final") // => [[0, 10], [1, "_test_"], [0, 20], [1, "_final"]]
 *
 * @param str - ソート対象の文字列
 * @returns [type, value]の配列。typeは0=数値、1=文字列
 */
export function naturalSortKey(str: string): Array<[number, number | string]> {
  const parts = str.match(/(\d+|\D+)/g) || [];
  return parts.map(part => {
    if (/^\d+$/.test(part)) {
      return [0, parseInt(part, 10)] as [number, number];
    } else {
      return [1, part] as [number, string];
    }
  });
}

/**
 * 自然順ソート比較関数
 * naturalSortKeyで生成されたソートキーを比較
 *
 * @example
 * const keys = [
 *   naturalSortKey("100_ユーザ管理"),
 *   naturalSortKey("10_サーバ構築"),
 *   naturalSortKey("2_認証機能")
 * ];
 * keys.sort(compareNaturalSort);
 * // => ["2_認証機能", "10_サーバ構築", "100_ユーザ管理"]
 *
 * @param a - 比較対象のソートキーA
 * @param b - 比較対象のソートキーB
 * @returns -1, 0, 1（標準的なソート比較関数の戻り値）
 */
export function compareNaturalSort(
  a: Array<[number, number | string]>,
  b: Array<[number, number | string]>
): number {
  const minLength = Math.min(a.length, b.length);

  for (let i = 0; i < minLength; i++) {
    const [typeA, valueA] = a[i];
    const [typeB, valueB] = b[i];

    // Type flag比較（数値=0が文字列=1より優先）
    if (typeA !== typeB) {
      return typeA - typeB;
    }

    // 同じタイプの場合は値を比較
    if (valueA < valueB) return -1;
    if (valueA > valueB) return 1;
  }

  // 全て同じ場合は長さで比較
  return a.length - b.length;
}
