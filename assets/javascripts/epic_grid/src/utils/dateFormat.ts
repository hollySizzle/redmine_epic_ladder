/**
 * 日付フォーマットユーティリティ
 *
 * mm/dd~mm/dd 形式で日付範囲を表示
 * 年が跨ぐ場合でも mm/dd 形式を維持
 */

/**
 * 日付文字列を mm/dd 形式にフォーマット
 * @param dateStr - ISO8601形式の日付文字列 (例: "2025-12-25")
 * @returns mm/dd 形式の文字列 (例: "12/25")
 */
function formatToMonthDay(dateStr: string): string {
  const date = new Date(dateStr);
  const month = date.getMonth() + 1; // 0-indexed なので +1
  const day = date.getDate();
  return `${month}/${day}`;
}

/**
 * 開始日と期日を "mm/dd~mm/dd" 形式でフォーマット
 *
 * @param startDate - 開始日 (ISO8601形式 or null)
 * @param dueDate - 期日 (ISO8601形式 or null)
 * @returns フォーマットされた日付範囲文字列
 *
 * @example
 * formatDateRange("2025-12-20", "2025-12-25") // "12/20~12/25"
 * formatDateRange(null, "2025-12-25")         // "~12/25"
 * formatDateRange("2025-12-20", null)         // "12/20~"
 * formatDateRange(null, null)                 // null
 * formatDateRange("2024-12-28", "2025-01-05") // "12/28~1/5" (年跨ぎでも mm/dd)
 */
export function formatDateRange(
  startDate: string | null | undefined,
  dueDate: string | null | undefined
): string | null {
  const hasStart = startDate != null && startDate !== '';
  const hasDue = dueDate != null && dueDate !== '';

  if (!hasStart && !hasDue) {
    return null;
  }

  const startStr = hasStart ? formatToMonthDay(startDate) : '';
  const dueStr = hasDue ? formatToMonthDay(dueDate) : '';

  if (hasStart && hasDue) {
    return `${startStr}~${dueStr}`;
  } else if (hasDue) {
    return `~${dueStr}`;
  } else {
    return `${startStr}~`;
  }
}
