/**
 * DOM操作ユーティリティ
 *
 * Issue要素へのスクロールとハイライト表示
 */

/**
 * Issueまでスムーススクロール
 *
 * @param issueId - IssueのID
 * @param issueType - Issueのタイプ
 * @returns スクロール成功したらtrue
 */
export function scrollToIssue(issueId: string, issueType: string): boolean {
  // data属性からDOM要素を検索
  const selectors = getIssueSelectors(issueId, issueType);

  for (const selector of selectors) {
    const element = document.querySelector(selector);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth', block: 'center' });
      return true;
    }
  }

  return false;
}

/**
 * Issue要素を一時的にハイライト表示（3秒間）
 *
 * @param issueId - IssueのID
 * @param issueType - Issueのタイプ
 */
export function highlightIssue(issueId: string, issueType: string): void {
  const selectors = getIssueSelectors(issueId, issueType);

  for (const selector of selectors) {
    const element = document.querySelector(selector);
    if (element) {
      // ハイライトクラスを追加
      element.classList.add('search-highlight');

      // 3秒後に削除
      setTimeout(() => {
        element.classList.remove('search-highlight');
      }, 3000);

      break;
    }
  }
}

/**
 * IssueタイプごとのCSS selectorを取得
 *
 * @param issueId - IssueのID
 * @param issueType - Issueのタイプ
 * @returns 検索候補のselector配列
 */
function getIssueSelectors(issueId: string, issueType: string): string[] {
  switch (issueType) {
    case 'epic':
      return [
        `[data-epic="${issueId}"]`,
        `.epic[data-epic="${issueId}"]`
      ];
    case 'feature':
      return [
        `[data-feature="${issueId}"]`,
        `.feature-card[data-feature="${issueId}"]`
      ];
    case 'user-story':
      return [
        `[data-story="${issueId}"]`,
        `.user-story[data-story="${issueId}"]`
      ];
    case 'task':
      return [
        `[data-task="${issueId}"]`,
        `.task[data-task="${issueId}"]`
      ];
    case 'test':
      return [
        `[data-test="${issueId}"]`,
        `.test[data-test="${issueId}"]`
      ];
    case 'bug':
      return [
        `[data-bug="${issueId}"]`,
        `.bug[data-bug="${issueId}"]`
      ];
    default:
      return [];
  }
}
