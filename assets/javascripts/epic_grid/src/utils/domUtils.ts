/**
 * DOM操作ユーティリティ
 *
 * Issue要素へのスクロールとハイライト表示
 */

/**
 * Issueまでスムーススクロール
 *
 * UserStory/Task/Test/Bugの場合は親のepic-version-wrapperを中央に配置
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
      // UserStory/Task/Test/Bugの場合は親のepic-version-wrapperを中央に配置
      if (['user-story', 'task', 'test', 'bug'].includes(issueType)) {
        const epicVersionWrapper = element.closest('.epic-version-wrapper');
        if (epicVersionWrapper) {
          epicVersionWrapper.scrollIntoView({ behavior: 'smooth', block: 'center' });
          return true;
        }
      }

      // それ以外（Epic/Feature）は通常通り
      element.scrollIntoView({ behavior: 'smooth', block: 'center' });
      return true;
    }
  }

  return false;
}

/**
 * 親階層のUserStoryを自動展開
 *
 * Task/Test/Bugの場合、親のUserStoryが折りたたまれていたら展開する
 *
 * @param issueId - IssueのID
 * @param issueType - Issueのタイプ
 */
export function expandParentUserStory(issueId: string, issueType: string): void {
  if (!['task', 'test', 'bug'].includes(issueType)) {
    return; // Task/Test/Bug以外は処理不要
  }

  const selectors = getIssueSelectors(issueId, issueType);

  for (const selector of selectors) {
    const element = document.querySelector(selector);
    if (element) {
      // 親のUserStoryを探す
      const userStoryCard = element.closest('.user-story');
      if (userStoryCard) {
        const collapseButton = userStoryCard.querySelector('.user-story-collapse-button');
        if (collapseButton) {
          const isCollapsed = collapseButton.getAttribute('aria-expanded') === 'false';
          if (isCollapsed) {
            // 折りたたまれていたらクリックして展開
            (collapseButton as HTMLElement).click();
          }
        }
      }
      break;
    }
  }
}

/**
 * フォーカスモードを有効化（他のカードを薄くする）
 *
 * @param issueId - フォーカスするIssueのID
 * @param issueType - フォーカスするIssueのタイプ
 */
export function enableFocusMode(issueId: string, issueType: string): void {
  const selectors = getIssueSelectors(issueId, issueType);

  for (const selector of selectors) {
    const targetElement = document.querySelector(selector);
    if (targetElement) {
      // グリッド全体にフォーカスモードクラスを追加
      const gridContainer = document.querySelector('.epic-grid');
      if (gridContainer) {
        gridContainer.classList.add('focus-mode');
      }

      // ターゲット要素にフォーカスクラスを追加
      targetElement.classList.add('focus-target');

      // 親のepic-version-wrapperにもフォーカスクラスを追加（少し見える）
      const epicVersionWrapper = targetElement.closest('.epic-version-wrapper');
      if (epicVersionWrapper) {
        epicVersionWrapper.classList.add('focus-parent');
      }

      // 3秒後にフォーカスモードを解除
      setTimeout(() => {
        if (gridContainer) {
          gridContainer.classList.remove('focus-mode');
        }
        targetElement.classList.remove('focus-target');
        if (epicVersionWrapper) {
          epicVersionWrapper.classList.remove('focus-parent');
        }
      }, 3000);

      break;
    }
  }
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
