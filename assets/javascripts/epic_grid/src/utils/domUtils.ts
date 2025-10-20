/**
 * DOM操作ユーティリティ
 *
 * Issue要素へのスクロールとハイライト表示
 */

import type { NormalizedEntities } from '../types/normalized-api';

/**
 * Epic/Featureから最もY方向に近い"Add User Story"ボタンを探す
 *
 * @param element - Epic/Feature要素
 * @returns 最も近いAddボタン、見つからない場合はnull
 */
function findNearestAddUserStoryButton(element: Element): Element | null {
  console.log('🔍 [findNearestAddUserStoryButton] Searching for Add User Story button...');

  // Epic/Feature配下の全AddUserStoryボタンを探す
  const addButtons = Array.from(
    document.querySelectorAll('[data-add-button="user-story"]')
  );

  console.log('🔍 [findNearestAddUserStoryButton] Found buttons:', addButtons.length);

  if (addButtons.length === 0) return null;

  const elementRect = element.getBoundingClientRect();
  const elementCenterY = elementRect.top + elementRect.height / 2;

  // Y座標が最も近いボタンを見つける
  let nearestButton: Element | null = null;
  let minDistance = Infinity;

  addButtons.forEach((button) => {
    const buttonRect = button.getBoundingClientRect();
    const buttonCenterY = buttonRect.top + buttonRect.height / 2;
    const distance = Math.abs(buttonCenterY - elementCenterY);

    console.log('🔍 [findNearestAddUserStoryButton] Button Y:', buttonCenterY, 'Distance:', distance);

    if (distance < minDistance) {
      minDistance = distance;
      nearestButton = button;
    }
  });

  console.log('🔍 [findNearestAddUserStoryButton] Nearest button found:', !!nearestButton, 'Distance:', minDistance);

  return nearestButton;
}

/**
 * Issueまでスムーススクロール（2段階: 上端 → scrollend → 中央）
 *
 * Epic/Featureの場合: 最もY方向に近い"Add User Story"ボタンにスクロール
 * UserStory/Task/Test/Bugの場合: 親のepic-version-wrapperを中央に配置
 * 視線誘導のため、まず上端に移動し、アニメーション完了後に中央に移動する
 *
 * @param issueId - IssueのID
 * @param issueType - Issueのタイプ
 * @returns スクロール成功したらtrue
 */
export function scrollToIssue(issueId: string, issueType: string): boolean {
  console.log('📜 [scrollToIssue] Called with:', { issueId, issueType });

  // data属性からDOM要素を検索
  const selectors = getIssueSelectors(issueId, issueType);
  console.log('📜 [scrollToIssue] Selectors:', selectors);

  for (const selector of selectors) {
    const element = document.querySelector(selector);
    console.log('📜 [scrollToIssue] Trying selector:', selector, 'Found:', !!element);

    if (element) {
      // Epic/Featureの場合は、最も近いAddUserStoryボタンをスクロール先にする
      let targetElement: Element = element;

      if (['epic', 'feature'].includes(issueType)) {
        const nearestButton = findNearestAddUserStoryButton(element);
        if (nearestButton) {
          console.log('📜 [scrollToIssue] Using nearest Add User Story button as target');
          targetElement = nearestButton;
        } else {
          console.log('📜 [scrollToIssue] No Add User Story button found, using original element');
        }
      }

      console.log('📜 [scrollToIssue] Target element:', targetElement.className);

      // スクロールコンテナを特定
      // すべてのissueタイプで epic-version-wrapper を優先的に使用
      let scrollContainer: Element | HTMLElement;

      if (['user-story', 'task', 'test', 'bug'].includes(issueType)) {
        // UserStory/Task/Test/Bug: 親階層のepic-version-wrapperを探す
        const epicVersionWrapper = targetElement.closest('.epic-version-wrapper');
        if (epicVersionWrapper) {
          scrollContainer = epicVersionWrapper;
          console.log('📜 [scrollToIssue] Using epic-version-wrapper as scroll container');
        } else {
          // フォールバック
          scrollContainer = targetElement.closest('.triple-split-layout__center')
            || targetElement.closest('.kanban-fullscreen')
            || document.documentElement;
          console.log('📜 [scrollToIssue] epic-version-wrapper not found, using fallback');
        }
      } else {
        // Epic/Feature: 最初に見つかったepic-version-wrapperを使用
        const firstEpicVersionWrapper = document.querySelector('.epic-version-wrapper');
        if (firstEpicVersionWrapper) {
          scrollContainer = firstEpicVersionWrapper;
          console.log('📜 [scrollToIssue] Using first epic-version-wrapper as scroll container');
        } else {
          // フォールバック
          scrollContainer = targetElement.closest('.triple-split-layout__center')
            || targetElement.closest('.kanban-fullscreen')
            || document.documentElement;
          console.log('📜 [scrollToIssue] epic-version-wrapper not found, using fallback');
        }
      }

      console.log('📜 [scrollToIssue] Scroll container:',
        scrollContainer === document.documentElement ? 'document.documentElement' : scrollContainer.className);

      // 2段階スクロール: 1. 上端に移動 → 2. scrollend後に中央に移動
      // Step 1: 上端に移動（視線誘導の開始点）
      console.log('📜 [scrollToIssue] Step 1: Scrolling to start...');

      // 手動でスクロール位置を計算（scrollIntoViewは既に見える要素には動かないため）
      const targetRect = targetElement.getBoundingClientRect();
      const containerRect = scrollContainer === document.documentElement
        ? { top: 0, left: 0, height: window.innerHeight, width: window.innerWidth }
        : scrollContainer.getBoundingClientRect();

      // コンテナ内での要素の相対位置を計算（Y方向）
      const elementTop = scrollContainer === document.documentElement
        ? targetRect.top + window.scrollY
        : targetRect.top - containerRect.top + scrollContainer.scrollTop;

      // コンテナ内での要素の相対位置を計算（X方向）
      const elementLeft = scrollContainer === document.documentElement
        ? targetRect.left + window.scrollX
        : targetRect.left - containerRect.left + scrollContainer.scrollLeft;

      console.log('📜 [scrollToIssue] Element position:', {
        elementTop,
        elementLeft,
        containerScrollTop: scrollContainer.scrollTop,
        containerScrollLeft: scrollContainer.scrollLeft,
        targetRectTop: targetRect.top,
        targetRectLeft: targetRect.left,
        containerRectTop: containerRect.top,
        containerRectLeft: containerRect.left
      });

      // Step 1: 上端左端にスクロール（まず要素を見える範囲に移動）
      const scrollDistanceY = Math.abs(elementTop - scrollContainer.scrollTop);
      const scrollDistanceX = Math.abs(elementLeft - scrollContainer.scrollLeft);
      const scrollDistance1 = Math.max(scrollDistanceY, scrollDistanceX);
      console.log('📜 [scrollToIssue] Step 1 scroll distance:', { x: scrollDistanceX, y: scrollDistanceY, max: scrollDistance1 });

      // デバッグ: scrollContainer の情報を詳細に出力
      const canScroll = scrollContainer.scrollHeight > scrollContainer.clientHeight;
      console.log('📜 [scrollToIssue] Scroll container details:', {
        tagName: scrollContainer.tagName,
        className: scrollContainer.className,
        scrollTop: scrollContainer.scrollTop,
        scrollHeight: scrollContainer.scrollHeight,
        clientHeight: scrollContainer.clientHeight,
        canScroll
      });

      if (!canScroll) {
        console.log('📜 [scrollToIssue] Container cannot scroll (all content visible). Relying on visual effects only.');
        return true; // 視覚効果（フォーカスモード、ハイライト）のみで対応
      }

      console.log('📜 [scrollToIssue] Calling scrollTo with:', { top: elementTop, left: elementLeft });
      scrollContainer.scrollTo({
        top: elementTop,
        left: elementLeft,
        behavior: 'smooth'
      });

      // Step 2: 中央スクロールを実行（一定時間後）
      console.log('📜 [scrollToIssue] Step 2: Scheduling center scroll...');

      // 中央スクロール実行関数
      const scrollToCenter = () => {
        console.log('📜 [scrollToIssue] Executing center scroll...');

        // 中央配置するための位置を計算
        const updatedTargetRect = targetElement.getBoundingClientRect();
        const updatedContainerRect = scrollContainer === document.documentElement
          ? { top: 0, left: 0, height: window.innerHeight, width: window.innerWidth }
          : scrollContainer.getBoundingClientRect();

        // Y方向の中央位置計算
        const updatedElementTop = scrollContainer === document.documentElement
          ? updatedTargetRect.top + window.scrollY
          : updatedTargetRect.top - updatedContainerRect.top + scrollContainer.scrollTop;

        const containerHeight = scrollContainer === document.documentElement
          ? window.innerHeight
          : scrollContainer.clientHeight;

        const elementHeight = targetElement.clientHeight;
        const centerOffsetY = (containerHeight - elementHeight) / 2;
        const centerPositionY = updatedElementTop - centerOffsetY;

        // X方向の中央位置計算
        const updatedElementLeft = scrollContainer === document.documentElement
          ? updatedTargetRect.left + window.scrollX
          : updatedTargetRect.left - updatedContainerRect.left + scrollContainer.scrollLeft;

        const containerWidth = scrollContainer === document.documentElement
          ? window.innerWidth
          : scrollContainer.clientWidth;

        const elementWidth = targetElement.clientWidth;
        const centerOffsetX = (containerWidth - elementWidth) / 2;
        // 左方向に20%ずらす（左側の余白を60%に）
        const leftShift = containerWidth * 0.2;
        const centerPositionX = updatedElementLeft - centerOffsetX - leftShift;

        const scrollDistanceY = Math.abs(centerPositionY - scrollContainer.scrollTop);
        const scrollDistanceX = Math.abs(centerPositionX - scrollContainer.scrollLeft);

        console.log('📜 [scrollToIssue] Center scroll calculation:', {
          y: {
            updatedElementTop,
            containerHeight,
            elementHeight,
            centerOffset: centerOffsetY,
            centerPosition: centerPositionY,
            currentScrollTop: scrollContainer.scrollTop,
            scrollDistance: scrollDistanceY
          },
          x: {
            updatedElementLeft,
            containerWidth,
            elementWidth,
            centerOffset: centerOffsetX,
            centerPosition: centerPositionX,
            currentScrollLeft: scrollContainer.scrollLeft,
            scrollDistance: scrollDistanceX
          }
        });

        scrollContainer.scrollTo({
          top: centerPositionY,
          left: centerPositionX,
          behavior: 'smooth'
        });
      };

      // スクロール距離に応じてタイミングを調整
      const delay = scrollDistance1 > 100 ? 600 : 200;
      console.log('📜 [scrollToIssue] Scheduling center scroll with delay:', delay, 'ms');

      setTimeout(() => {
        scrollToCenter();
      }, delay);

      return true;
    }
  }

  console.warn('📜 [scrollToIssue] Element not found!');
  return false;
}

/**
 * 親階層のUserStoryを自動展開
 *
 * Task/Test/Bugの場合、親のUserStoryが折りたたまれていたら展開する
 * entitiesから親UserStoryのIDを取得し、DOM要素が存在しない場合でも展開可能
 *
 * @param issueId - IssueのID
 * @param issueType - Issueのタイプ
 * @param entities - 正規化されたエンティティデータ
 * @returns 展開処理を実行したかどうか
 */
export function expandParentUserStory(
  issueId: string,
  issueType: string,
  entities: NormalizedEntities
): boolean {
  console.log('📂 [expandParentUserStory] Called with:', { issueId, issueType });

  if (!['task', 'test', 'bug'].includes(issueType)) {
    console.log('📂 [expandParentUserStory] Not task/test/bug, skipping');
    return false; // Task/Test/Bug以外は処理不要
  }

  // entitiesから親UserStoryのIDを取得
  let parentUserStoryId: string | undefined;

  if (issueType === 'task') {
    const task = entities.tasks[issueId];
    parentUserStoryId = task?.parent_user_story_id;
  } else if (issueType === 'test') {
    const test = entities.tests[issueId];
    parentUserStoryId = test?.parent_user_story_id;
  } else if (issueType === 'bug') {
    const bug = entities.bugs[issueId];
    parentUserStoryId = bug?.parent_user_story_id;
  }

  if (!parentUserStoryId) {
    console.log('📂 [expandParentUserStory] Parent UserStory ID not found in entities');
    return false;
  }

  console.log('📂 [expandParentUserStory] Parent UserStory ID:', parentUserStoryId);

  // 親UserStoryのDOM要素を探す
  const userStoryElement = document.querySelector(`[data-story="${parentUserStoryId}"]`);

  if (!userStoryElement) {
    console.log('📂 [expandParentUserStory] Parent UserStory element not found in DOM');
    return false;
  }

  console.log('📂 [expandParentUserStory] Found parent UserStory element');

  // 折り畳みボタンを探す
  const collapseButton = userStoryElement.querySelector('.user-story-collapse-toggle') as HTMLButtonElement;

  if (!collapseButton) {
    console.log('📂 [expandParentUserStory] Collapse button not found');
    return false;
  }

  // ボタンのテキストで折り畳み状態を判定（▶ = 折り畳み中、▼ = 展開中）
  const isCollapsed = collapseButton.textContent?.trim() === '▶';
  console.log('📂 [expandParentUserStory] Is collapsed:', isCollapsed);

  if (isCollapsed) {
    // 折りたたまれていたらクリックして展開
    console.log('📂 [expandParentUserStory] Clicking to expand...');
    collapseButton.click();
    console.log('📂 [expandParentUserStory] ✅ Expanded UserStory:', parentUserStoryId);
    return true;
  }

  console.log('📂 [expandParentUserStory] Already expanded, no action needed');
  return false;
}

/**
 * フォーカスモードを有効化（他のカードを薄くする）
 *
 * @param issueId - フォーカスするIssueのID
 * @param issueType - フォーカスするIssueのタイプ
 */
export function enableFocusMode(issueId: string, issueType: string): void {
  console.log('🎯 [enableFocusMode] Called with:', { issueId, issueType });

  const selectors = getIssueSelectors(issueId, issueType);
  console.log('🎯 [enableFocusMode] Selectors:', selectors);

  for (const selector of selectors) {
    const targetElement = document.querySelector(selector);
    console.log('🎯 [enableFocusMode] Trying selector:', selector, 'Found:', !!targetElement);

    if (targetElement) {
      // グリッド全体にフォーカスモードクラスを追加
      const gridContainer = document.querySelector('.epic-grid');
      console.log('🎯 [enableFocusMode] Grid container found:', !!gridContainer);

      if (gridContainer) {
        gridContainer.classList.add('focus-mode');
        console.log('🎯 [enableFocusMode] Added focus-mode class to grid');
      }

      // ターゲット要素にフォーカスクラスを追加
      targetElement.classList.add('focus-target');
      console.log('🎯 [enableFocusMode] Added focus-target class to element');

      // Epic/Featureの場合、sticky cellにフォーカスクラスを追加
      let epicCell: Element | null = null;
      let featureCell: Element | null = null;

      if (issueType === 'epic') {
        epicCell = targetElement.closest('.epic-cell');
        if (epicCell) {
          epicCell.classList.add('epic-cell--focused');
          console.log('🎯 [enableFocusMode] Added epic-cell--focused class');
        }
      } else if (issueType === 'feature') {
        featureCell = targetElement.closest('.feature-cell');
        if (featureCell) {
          featureCell.classList.add('feature-cell--focused');
          console.log('🎯 [enableFocusMode] Added feature-cell--focused class');
        }
      }

      // 親のepic-version-wrapperにもフォーカスクラスを追加（少し見える）
      const epicVersionWrapper = targetElement.closest('.epic-version-wrapper');
      console.log('🎯 [enableFocusMode] Epic version wrapper found:', !!epicVersionWrapper);

      if (epicVersionWrapper) {
        epicVersionWrapper.classList.add('focus-parent');
        console.log('🎯 [enableFocusMode] Added focus-parent class to wrapper');
      }

      // 3秒後にフォーカスモードを解除
      console.log('🎯 [enableFocusMode] Setting timeout for 3s cleanup...');
      setTimeout(() => {
        console.log('🎯 [enableFocusMode] Timeout fired, removing classes...');
        if (gridContainer) {
          gridContainer.classList.remove('focus-mode');
        }
        targetElement.classList.remove('focus-target');

        // Epic/Featureの場合、sticky cellのフォーカスクラスを削除
        if (epicCell) {
          epicCell.classList.remove('epic-cell--focused');
          console.log('🎯 [enableFocusMode] Removed epic-cell--focused class');
        }
        if (featureCell) {
          featureCell.classList.remove('feature-cell--focused');
          console.log('🎯 [enableFocusMode] Removed feature-cell--focused class');
        }

        if (epicVersionWrapper) {
          epicVersionWrapper.classList.remove('focus-parent');
        }
        console.log('🎯 [enableFocusMode] Cleanup done');
      }, 3000);

      break;
    }
  }
  console.log('🎯 [enableFocusMode] Done');
}

/**
 * Issue要素を一時的にハイライト表示（3秒間）
 *
 * @param issueId - IssueのID
 * @param issueType - Issueのタイプ
 */
export function highlightIssue(issueId: string, issueType: string): void {
  console.log('✨ [highlightIssue] Called with:', { issueId, issueType });

  // Epic/Featureはstickyヘッダー専用のボーダー＆影強調アニメーションを使用
  if (issueType === 'epic') {
    const selectors = getIssueSelectors(issueId, issueType);
    for (const selector of selectors) {
      const element = document.querySelector(selector);
      if (element) {
        const epicCell = element.closest('.epic-cell');
        if (epicCell) {
          epicCell.classList.add('epic-cell--highlight');
          console.log('✨ [highlightIssue] Added epic-cell--highlight class');

          setTimeout(() => {
            epicCell.classList.remove('epic-cell--highlight');
            console.log('✨ [highlightIssue] Removed epic-cell--highlight class');
          }, 3000);
        }
        break;
      }
    }
    return;
  } else if (issueType === 'feature') {
    const selectors = getIssueSelectors(issueId, issueType);
    for (const selector of selectors) {
      const element = document.querySelector(selector);
      if (element) {
        const featureCell = element.closest('.feature-cell');
        if (featureCell) {
          featureCell.classList.add('feature-cell--highlight');
          console.log('✨ [highlightIssue] Added feature-cell--highlight class');

          setTimeout(() => {
            featureCell.classList.remove('feature-cell--highlight');
            console.log('✨ [highlightIssue] Removed feature-cell--highlight class');
          }, 3000);
        }
        break;
      }
    }
    return;
  }

  const selectors = getIssueSelectors(issueId, issueType);
  console.log('✨ [highlightIssue] Selectors:', selectors);

  for (const selector of selectors) {
    const element = document.querySelector(selector);
    console.log('✨ [highlightIssue] Trying selector:', selector, 'Found:', !!element);

    if (element) {
      // ハイライトクラスを追加
      element.classList.add('search-highlight');
      console.log('✨ [highlightIssue] Added search-highlight class');

      // 3秒後に削除
      console.log('✨ [highlightIssue] Setting timeout for 3s cleanup...');
      setTimeout(() => {
        console.log('✨ [highlightIssue] Timeout fired, removing search-highlight class');
        element.classList.remove('search-highlight');
      }, 3000);

      break;
    }
  }
  console.log('✨ [highlightIssue] Done');
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
