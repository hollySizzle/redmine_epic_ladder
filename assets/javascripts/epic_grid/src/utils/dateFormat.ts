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
 * 曜日を取得 (日本語)
 * @param dateStr - ISO8601形式の日付文字列 (例: "2025-12-25")
 * @returns 日本語の曜日 (例: "水")
 */
function getDayOfWeek(dateStr: string): string {
  const date = new Date(dateStr);
  const daysOfWeek = ['日', '月', '火', '水', '木', '金', '土'];
  return daysOfWeek[date.getDay()];
}

/**
 * 単一の日付を mm/dd 形式でフォーマット (Version期日表示用)
 *
 * @param date - ISO8601形式の日付文字列 or null
 * @returns mm/dd 形式の文字列、または null
 *
 * @example
 * formatDate("2025-12-25")  // "12/25"
 * formatDate(null)          // null
 * formatDate("")            // null
 */
export function formatDate(date: string | null | undefined): string | null {
  if (!date || date === '') {
    return null;
  }
  return formatToMonthDay(date);
}

/**
 * 単一の日付を mm/dd(曜日) 形式でフォーマット (Version期日表示用)
 *
 * @param date - ISO8601形式の日付文字列 or null
 * @returns mm/dd(曜日) 形式の文字列、または null
 *
 * @example
 * formatDateWithDayOfWeek("2025-01-15")  // "1/15(水)"
 * formatDateWithDayOfWeek(null)          // null
 * formatDateWithDayOfWeek("")            // null
 */
export function formatDateWithDayOfWeek(date: string | null | undefined): string | null {
  if (!date || date === '') {
    return null;
  }
  const formattedDate = formatToMonthDay(date);
  const dayOfWeek = getDayOfWeek(date);
  return `${formattedDate}(${dayOfWeek})`;
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

/**
 * 期日が超過しているかチェック
 *
 * @param dueDate - ISO8601形式の期日文字列 or null
 * @returns 期日が今日より前ならtrue、期日未設定またはまだ期日内ならfalse
 *
 * @example
 * isOverdue("2025-01-01")  // true (過去の日付)
 * isOverdue("2099-12-31")  // false (未来の日付)
 * isOverdue(null)          // false (期日未設定)
 * isOverdue("")            // false (期日未設定)
 */
export function isOverdue(dueDate: string | null | undefined): boolean {
  if (!dueDate || dueDate === '') {
    return false;
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0); // 時刻をリセットして日付のみで比較

  const due = new Date(dueDate);
  due.setHours(0, 0, 0, 0);

  return due < today;
}
