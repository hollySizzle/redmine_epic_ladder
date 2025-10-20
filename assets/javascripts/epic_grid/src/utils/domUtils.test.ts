import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { scrollToIssue, highlightIssue, expandParentUserStory, enableFocusMode } from './domUtils';

describe('domUtils', () => {
  beforeEach(() => {
    document.body.innerHTML = '';
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('scrollToIssue', () => {
    beforeEach(() => {
      vi.useFakeTimers();
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it('Epic要素を2段階スクロールする（上端 → timeout → 中央）', async () => {
      // Setup - スクロールコンテナも作成
      const scrollContainer = document.createElement('div');
      scrollContainer.className = 'triple-split-layout__center';

      // スクロール可能にする（scrollHeight > clientHeight）
      Object.defineProperty(scrollContainer, 'scrollHeight', { value: 1000, configurable: true });
      Object.defineProperty(scrollContainer, 'clientHeight', { value: 500, configurable: true });
      Object.defineProperty(scrollContainer, 'scrollTop', { value: 0, writable: true, configurable: true });
      Object.defineProperty(scrollContainer, 'scrollLeft', { value: 0, writable: true, configurable: true });

      const epicDiv = document.createElement('div');
      epicDiv.setAttribute('data-epic', '123');
      epicDiv.className = 'epic';

      scrollContainer.appendChild(epicDiv);
      document.body.appendChild(scrollContainer);

      // getBoundingClientRect をモック
      vi.spyOn(epicDiv, 'getBoundingClientRect').mockReturnValue({
        top: 100, left: 50, width: 200, height: 100, right: 250, bottom: 200, x: 50, y: 100, toJSON: () => ({})
      } as DOMRect);

      vi.spyOn(scrollContainer, 'getBoundingClientRect').mockReturnValue({
        top: 0, left: 0, width: 800, height: 500, right: 800, bottom: 500, x: 0, y: 0, toJSON: () => ({})
      } as DOMRect);

      const scrollToMock = vi.fn();
      scrollContainer.scrollTo = scrollToMock;

      // Execute
      const result = scrollToIssue('123', 'epic');

      // Assert - 1st call (上端左端)
      expect(result).toBe(true);
      expect(scrollToMock).toHaveBeenCalledTimes(1);
      expect(scrollToMock).toHaveBeenCalledWith({
        top: expect.any(Number),
        left: expect.any(Number),
        behavior: 'smooth'
      });

      // Assert - 500ms後に2nd call (フォールバック)
      vi.advanceTimersByTime(500);
      expect(scrollToMock).toHaveBeenCalledTimes(2);
      expect(scrollToMock).toHaveBeenNthCalledWith(2, {
        top: expect.any(Number),
        left: expect.any(Number),
        behavior: 'smooth'
      });
    });

    it('scrollendが発火しない場合、フォールバックタイマー(500ms)で2段階目スクロールを実行', () => {
      // Setup
      const scrollContainer = document.createElement('div');
      scrollContainer.className = 'triple-split-layout__center';

      // スクロール可能にする
      Object.defineProperty(scrollContainer, 'scrollHeight', { value: 1000, configurable: true });
      Object.defineProperty(scrollContainer, 'clientHeight', { value: 500, configurable: true });
      Object.defineProperty(scrollContainer, 'scrollTop', { value: 0, writable: true, configurable: true });
      Object.defineProperty(scrollContainer, 'scrollLeft', { value: 0, writable: true, configurable: true });

      const epicDiv = document.createElement('div');
      epicDiv.setAttribute('data-epic', '456');
      epicDiv.className = 'epic';

      scrollContainer.appendChild(epicDiv);
      document.body.appendChild(scrollContainer);

      // getBoundingClientRect をモック
      vi.spyOn(epicDiv, 'getBoundingClientRect').mockReturnValue({
        top: 100, left: 50, width: 200, height: 100, right: 250, bottom: 200, x: 50, y: 100, toJSON: () => ({})
      } as DOMRect);

      vi.spyOn(scrollContainer, 'getBoundingClientRect').mockReturnValue({
        top: 0, left: 0, width: 800, height: 500, right: 800, bottom: 500, x: 0, y: 0, toJSON: () => ({})
      } as DOMRect);

      const scrollToMock = vi.fn();
      scrollContainer.scrollTo = scrollToMock;

      // Execute
      const result = scrollToIssue('456', 'epic');

      // Assert - 1st call (上端)
      expect(result).toBe(true);
      expect(scrollToMock).toHaveBeenCalledTimes(1);

      // Assert - 500ms経過後に2nd call (フォールバック)
      vi.advanceTimersByTime(500);
      expect(scrollToMock).toHaveBeenCalledTimes(2);
    });

    it('Feature要素を2段階スクロールする（上端 → timeout → 中央）', () => {
      // Setup - スクロールコンテナも作成
      const scrollContainer = document.createElement('div');
      scrollContainer.className = 'triple-split-layout__center';

      // スクロール可能にする
      Object.defineProperty(scrollContainer, 'scrollHeight', { value: 1000, configurable: true });
      Object.defineProperty(scrollContainer, 'clientHeight', { value: 500, configurable: true });
      Object.defineProperty(scrollContainer, 'scrollTop', { value: 0, writable: true, configurable: true });
      Object.defineProperty(scrollContainer, 'scrollLeft', { value: 0, writable: true, configurable: true });

      const featureDiv = document.createElement('div');
      featureDiv.setAttribute('data-feature', '789');
      featureDiv.className = 'feature-card';

      scrollContainer.appendChild(featureDiv);
      document.body.appendChild(scrollContainer);

      // getBoundingClientRect をモック
      vi.spyOn(featureDiv, 'getBoundingClientRect').mockReturnValue({
        top: 100, left: 50, width: 200, height: 100, right: 250, bottom: 200, x: 50, y: 100, toJSON: () => ({})
      } as DOMRect);

      vi.spyOn(scrollContainer, 'getBoundingClientRect').mockReturnValue({
        top: 0, left: 0, width: 800, height: 500, right: 800, bottom: 500, x: 0, y: 0, toJSON: () => ({})
      } as DOMRect);

      const scrollToMock = vi.fn();
      scrollContainer.scrollTo = scrollToMock;

      // Execute
      const result = scrollToIssue('789', 'feature');

      // Assert - 1st call (上端)
      expect(result).toBe(true);
      expect(scrollToMock).toHaveBeenCalledTimes(1);

      // Assert - 500ms後に2nd call
      vi.advanceTimersByTime(500);
      expect(scrollToMock).toHaveBeenCalledTimes(2);
    });

    it('UserStoryの場合は親のepic-version-wrapperを2段階スクロールする', () => {
      // Setup - スクロールコンテナも作成
      const scrollContainer = document.createElement('div');
      scrollContainer.className = 'triple-split-layout__center';

      const epicVersionWrapper = document.createElement('div');
      epicVersionWrapper.className = 'epic-version-wrapper';

      // epic-version-wrapperをスクロール可能にする
      Object.defineProperty(epicVersionWrapper, 'scrollHeight', { value: 1000, configurable: true });
      Object.defineProperty(epicVersionWrapper, 'clientHeight', { value: 500, configurable: true });
      Object.defineProperty(epicVersionWrapper, 'scrollTop', { value: 0, writable: true, configurable: true });
      Object.defineProperty(epicVersionWrapper, 'scrollLeft', { value: 0, writable: true, configurable: true });

      const storyDiv = document.createElement('div');
      storyDiv.setAttribute('data-story', '1001');
      storyDiv.className = 'user-story';

      epicVersionWrapper.appendChild(storyDiv);
      scrollContainer.appendChild(epicVersionWrapper);
      document.body.appendChild(scrollContainer);

      // getBoundingClientRect をモック
      vi.spyOn(storyDiv, 'getBoundingClientRect').mockReturnValue({
        top: 100, left: 50, width: 200, height: 100, right: 250, bottom: 200, x: 50, y: 100, toJSON: () => ({})
      } as DOMRect);

      vi.spyOn(epicVersionWrapper, 'getBoundingClientRect').mockReturnValue({
        top: 0, left: 0, width: 800, height: 500, right: 800, bottom: 500, x: 0, y: 0, toJSON: () => ({})
      } as DOMRect);

      const wrapperScrollToMock = vi.fn();
      epicVersionWrapper.scrollTo = wrapperScrollToMock;

      // Execute
      const result = scrollToIssue('1001', 'user-story');

      // Assert - 1st call (上端)
      expect(result).toBe(true);
      expect(wrapperScrollToMock).toHaveBeenCalledTimes(1);

      // Assert - 500ms後に2nd call (中央)
      vi.advanceTimersByTime(500);
      expect(wrapperScrollToMock).toHaveBeenCalledTimes(2);
    });

    it('Taskの場合は親のepic-version-wrapperを2段階スクロールする', () => {
      // Setup - スクロールコンテナも作成
      const scrollContainer = document.createElement('div');
      scrollContainer.className = 'triple-split-layout__center';

      const epicVersionWrapper = document.createElement('div');
      epicVersionWrapper.className = 'epic-version-wrapper';

      // epic-version-wrapperをスクロール可能にする
      Object.defineProperty(epicVersionWrapper, 'scrollHeight', { value: 1000, configurable: true });
      Object.defineProperty(epicVersionWrapper, 'clientHeight', { value: 500, configurable: true });
      Object.defineProperty(epicVersionWrapper, 'scrollTop', { value: 0, writable: true, configurable: true });
      Object.defineProperty(epicVersionWrapper, 'scrollLeft', { value: 0, writable: true, configurable: true });

      const taskDiv = document.createElement('div');
      taskDiv.setAttribute('data-task', '2001');
      taskDiv.className = 'task';

      epicVersionWrapper.appendChild(taskDiv);
      scrollContainer.appendChild(epicVersionWrapper);
      document.body.appendChild(scrollContainer);

      // getBoundingClientRect をモック
      vi.spyOn(taskDiv, 'getBoundingClientRect').mockReturnValue({
        top: 100, left: 50, width: 200, height: 100, right: 250, bottom: 200, x: 50, y: 100, toJSON: () => ({})
      } as DOMRect);

      vi.spyOn(epicVersionWrapper, 'getBoundingClientRect').mockReturnValue({
        top: 0, left: 0, width: 800, height: 500, right: 800, bottom: 500, x: 0, y: 0, toJSON: () => ({})
      } as DOMRect);

      const wrapperScrollToMock = vi.fn();
      epicVersionWrapper.scrollTo = wrapperScrollToMock;

      // Execute
      const result = scrollToIssue('2001', 'task');

      // Assert - 1st call (上端)
      expect(result).toBe(true);
      expect(wrapperScrollToMock).toHaveBeenCalledTimes(1);

      // Assert - 500ms後に2nd call
      vi.advanceTimersByTime(500);
      expect(wrapperScrollToMock).toHaveBeenCalledTimes(2);
    });

    it('UserStoryがepic-version-wrapper外にある場合は2段階スクロール', () => {
      // Setup - スクロールコンテナも作成
      const scrollContainer = document.createElement('div');
      scrollContainer.className = 'triple-split-layout__center';

      // スクロール可能にする
      Object.defineProperty(scrollContainer, 'scrollHeight', { value: 1000, configurable: true });
      Object.defineProperty(scrollContainer, 'clientHeight', { value: 500, configurable: true });
      Object.defineProperty(scrollContainer, 'scrollTop', { value: 0, writable: true, configurable: true });
      Object.defineProperty(scrollContainer, 'scrollLeft', { value: 0, writable: true, configurable: true });

      const storyDiv = document.createElement('div');
      storyDiv.setAttribute('data-story', '3001');
      storyDiv.className = 'user-story';

      scrollContainer.appendChild(storyDiv);
      document.body.appendChild(scrollContainer);

      // getBoundingClientRect をモック
      vi.spyOn(storyDiv, 'getBoundingClientRect').mockReturnValue({
        top: 100, left: 50, width: 200, height: 100, right: 250, bottom: 200, x: 50, y: 100, toJSON: () => ({})
      } as DOMRect);

      vi.spyOn(scrollContainer, 'getBoundingClientRect').mockReturnValue({
        top: 0, left: 0, width: 800, height: 500, right: 800, bottom: 500, x: 0, y: 0, toJSON: () => ({})
      } as DOMRect);

      const scrollToMock = vi.fn();
      scrollContainer.scrollTo = scrollToMock;

      // Execute
      const result = scrollToIssue('3001', 'user-story');

      // Assert - 1st call (上端)
      expect(result).toBe(true);
      expect(scrollToMock).toHaveBeenCalledTimes(1);

      // Assert - 500ms後に2nd call
      vi.advanceTimersByTime(500);
      expect(scrollToMock).toHaveBeenCalledTimes(2);
    });

    it('存在しない要素の場合はfalseを返す', () => {
      // Execute
      const result = scrollToIssue('999', 'epic');

      // Assert
      expect(result).toBe(false);
    });
  });

  describe('expandParentUserStory', () => {
    it('Task要素の親UserStoryが折りたたまれていたら展開する', () => {
      // Setup
      const userStoryDiv = document.createElement('div');
      userStoryDiv.className = 'user-story';

      const collapseButton = document.createElement('button');
      collapseButton.className = 'user-story-collapse-button';
      collapseButton.setAttribute('aria-expanded', 'false');
      const clickMock = vi.fn();
      collapseButton.addEventListener('click', clickMock);

      const taskDiv = document.createElement('div');
      taskDiv.setAttribute('data-task', '111');
      taskDiv.className = 'task';

      userStoryDiv.appendChild(collapseButton);
      userStoryDiv.appendChild(taskDiv);
      document.body.appendChild(userStoryDiv);

      // Execute
      expandParentUserStory('111', 'task');

      // Assert
      expect(clickMock).toHaveBeenCalledOnce();
    });

    it('Task要素の親UserStoryが既に展開済みなら何もしない', () => {
      // Setup
      const userStoryDiv = document.createElement('div');
      userStoryDiv.className = 'user-story';

      const collapseButton = document.createElement('button');
      collapseButton.className = 'user-story-collapse-button';
      collapseButton.setAttribute('aria-expanded', 'true'); // 展開済み
      const clickMock = vi.fn();
      collapseButton.addEventListener('click', clickMock);

      const taskDiv = document.createElement('div');
      taskDiv.setAttribute('data-task', '222');
      taskDiv.className = 'task';

      userStoryDiv.appendChild(collapseButton);
      userStoryDiv.appendChild(taskDiv);
      document.body.appendChild(userStoryDiv);

      // Execute
      expandParentUserStory('222', 'task');

      // Assert
      expect(clickMock).not.toHaveBeenCalled();
    });

    it('UserStory要素の場合は何もしない（対象外）', () => {
      // Setup
      const userStoryDiv = document.createElement('div');
      userStoryDiv.setAttribute('data-story', '333');
      userStoryDiv.className = 'user-story';
      document.body.appendChild(userStoryDiv);

      // Execute (should not throw)
      expect(() => {
        expandParentUserStory('333', 'user-story');
      }).not.toThrow();
    });

    it('Epic要素の場合は何もしない（対象外）', () => {
      // Setup
      const epicDiv = document.createElement('div');
      epicDiv.setAttribute('data-epic', '444');
      epicDiv.className = 'epic';
      document.body.appendChild(epicDiv);

      // Execute (should not throw)
      expect(() => {
        expandParentUserStory('444', 'epic');
      }).not.toThrow();
    });
  });

  describe('enableFocusMode', () => {
    beforeEach(() => {
      vi.useFakeTimers();
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it('UserStory要素にフォーカスクラスを追加し、グリッドにフォーカスモードを適用する', () => {
      // Setup
      const gridContainer = document.createElement('div');
      gridContainer.className = 'epic-grid';

      const epicVersionWrapper = document.createElement('div');
      epicVersionWrapper.className = 'epic-version-wrapper';

      const storyDiv = document.createElement('div');
      storyDiv.setAttribute('data-story', '555');
      storyDiv.className = 'user-story';

      epicVersionWrapper.appendChild(storyDiv);
      gridContainer.appendChild(epicVersionWrapper);
      document.body.appendChild(gridContainer);

      // Execute
      enableFocusMode('555', 'user-story');

      // Assert - immediately after
      expect(gridContainer.classList.contains('focus-mode')).toBe(true);
      expect(storyDiv.classList.contains('focus-target')).toBe(true);
      expect(epicVersionWrapper.classList.contains('focus-parent')).toBe(true);

      // Assert - after 3 seconds
      vi.advanceTimersByTime(3000);
      expect(gridContainer.classList.contains('focus-mode')).toBe(false);
      expect(storyDiv.classList.contains('focus-target')).toBe(false);
      expect(epicVersionWrapper.classList.contains('focus-parent')).toBe(false);
    });

    it('Epic要素にフォーカスクラスを追加する（epic-version-wrapper外なのでparentなし）', () => {
      // Setup
      const gridContainer = document.createElement('div');
      gridContainer.className = 'epic-grid';

      const epicDiv = document.createElement('div');
      epicDiv.setAttribute('data-epic', '666');
      epicDiv.className = 'epic';

      gridContainer.appendChild(epicDiv);
      document.body.appendChild(gridContainer);

      // Execute
      enableFocusMode('666', 'epic');

      // Assert
      expect(gridContainer.classList.contains('focus-mode')).toBe(true);
      expect(epicDiv.classList.contains('focus-target')).toBe(true);

      vi.advanceTimersByTime(3000);
      expect(gridContainer.classList.contains('focus-mode')).toBe(false);
      expect(epicDiv.classList.contains('focus-target')).toBe(false);
    });

    it('存在しない要素の場合は何もしない', () => {
      // Execute (should not throw)
      expect(() => {
        enableFocusMode('999', 'epic');
      }).not.toThrow();
    });
  });

  describe('highlightIssue', () => {
    beforeEach(() => {
      vi.useFakeTimers();
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it('Epic要素にハイライトクラスを追加し、3秒後に削除する', () => {
      // Setup
      const epicDiv = document.createElement('div');
      epicDiv.setAttribute('data-epic', '123');
      document.body.appendChild(epicDiv);

      // Execute
      highlightIssue('123', 'epic');

      // Assert - Epic/Featureはstickyヘッダーなのでハイライトをスキップ
      expect(epicDiv.classList.contains('search-highlight')).toBe(false);
    });

    it('UserStory要素にハイライトクラスを追加する', () => {
      // Setup
      const storyDiv = document.createElement('div');
      storyDiv.setAttribute('data-story', '789');
      document.body.appendChild(storyDiv);

      // Execute
      highlightIssue('789', 'user-story');

      // Assert
      expect(storyDiv.classList.contains('search-highlight')).toBe(true);

      vi.advanceTimersByTime(3000);
      expect(storyDiv.classList.contains('search-highlight')).toBe(false);
    });

    it('存在しない要素の場合は何もしない', () => {
      // Execute (should not throw)
      expect(() => {
        highlightIssue('999', 'epic');
      }).not.toThrow();
    });
  });
});
