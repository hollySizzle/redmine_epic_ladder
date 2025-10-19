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

    it.skip('Epic要素を2段階スクロールする（上端 → scrollend → 中央）', async () => {
      // Setup - スクロールコンテナも作成
      const scrollContainer = document.createElement('div');
      scrollContainer.className = 'triple-split-layout__center';

      const epicDiv = document.createElement('div');
      epicDiv.setAttribute('data-epic', '123');
      epicDiv.className = 'epic';

      scrollContainer.appendChild(epicDiv);
      document.body.appendChild(scrollContainer);

      const scrollIntoViewMock = vi.fn();
      epicDiv.scrollIntoView = scrollIntoViewMock;

      // scrollendイベントをシミュレート（スクロールコンテナに対して）
      let scrollendCallback: (() => void) | null = null;
      const addEventListenerSpy = vi.spyOn(scrollContainer, 'addEventListener').mockImplementation((event, callback) => {
        if (event === 'scrollend') {
          scrollendCallback = callback as () => void;
        }
      });

      // Execute
      const result = scrollToIssue('123', 'epic');

      // Assert - 1st call (上端)
      expect(result).toBe(true);
      expect(scrollIntoViewMock).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'start'
      });
      expect(scrollIntoViewMock).toHaveBeenCalledTimes(1);

      // Assert - scrollend イベント発火後に2nd call (中央)
      expect(scrollendCallback).not.toBeNull();
      scrollendCallback!();

      expect(scrollIntoViewMock).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'center'
      });
      expect(scrollIntoViewMock).toHaveBeenCalledTimes(2);

      addEventListenerSpy.mockRestore();
    });

    it.skip('scrollendが発火しない場合、フォールバックタイマー(500ms)で2段階目スクロールを実行', () => {
      // Setup
      const scrollContainer = document.createElement('div');
      scrollContainer.className = 'triple-split-layout__center';

      const epicDiv = document.createElement('div');
      epicDiv.setAttribute('data-epic', '456');
      epicDiv.className = 'epic';

      scrollContainer.appendChild(epicDiv);
      document.body.appendChild(scrollContainer);

      const scrollIntoViewMock = vi.fn();
      epicDiv.scrollIntoView = scrollIntoViewMock;

      // Execute
      const result = scrollToIssue('456', 'epic');

      // Assert - 1st call (上端)
      expect(result).toBe(true);
      expect(scrollIntoViewMock).toHaveBeenCalledTimes(1);

      // Assert - 500ms経過後に2nd call (フォールバック)
      vi.advanceTimersByTime(500);
      expect(scrollIntoViewMock).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'center'
      });
      expect(scrollIntoViewMock).toHaveBeenCalledTimes(2);
    });

    it.skip('Feature要素を2段階スクロールする（上端 → scrollend → 中央）', () => {
      // Setup - スクロールコンテナも作成
      const scrollContainer = document.createElement('div');
      scrollContainer.className = 'triple-split-layout__center';

      const featureDiv = document.createElement('div');
      featureDiv.setAttribute('data-feature', '789');
      featureDiv.className = 'feature-card';

      scrollContainer.appendChild(featureDiv);
      document.body.appendChild(scrollContainer);

      const scrollIntoViewMock = vi.fn();
      featureDiv.scrollIntoView = scrollIntoViewMock;

      // scrollendイベントをシミュレート
      let scrollendCallback: (() => void) | null = null;
      const addEventListenerSpy = vi.spyOn(scrollContainer, 'addEventListener').mockImplementation((event, callback) => {
        if (event === 'scrollend') {
          scrollendCallback = callback as () => void;
        }
      });

      // Execute
      const result = scrollToIssue('789', 'feature');

      // Assert - 1st call (上端)
      expect(result).toBe(true);
      expect(scrollIntoViewMock).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'start'
      });

      // Assert - scrollend後に2nd call
      scrollendCallback!();
      expect(scrollIntoViewMock).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'center'
      });
      expect(scrollIntoViewMock).toHaveBeenCalledTimes(2);

      addEventListenerSpy.mockRestore();
    });

    it.skip('UserStoryの場合は親のepic-version-wrapperを2段階スクロールする', () => {
      // Setup - スクロールコンテナも作成
      const scrollContainer = document.createElement('div');
      scrollContainer.className = 'triple-split-layout__center';

      const epicVersionWrapper = document.createElement('div');
      epicVersionWrapper.className = 'epic-version-wrapper';

      const storyDiv = document.createElement('div');
      storyDiv.setAttribute('data-story', '1001');
      storyDiv.className = 'user-story';

      epicVersionWrapper.appendChild(storyDiv);
      scrollContainer.appendChild(epicVersionWrapper);
      document.body.appendChild(scrollContainer);

      const wrapperScrollMock = vi.fn();
      const storyScrollMock = vi.fn();
      epicVersionWrapper.scrollIntoView = wrapperScrollMock;
      storyDiv.scrollIntoView = storyScrollMock;

      // scrollendイベントをシミュレート
      let scrollendCallback: (() => void) | null = null;
      const addEventListenerSpy = vi.spyOn(scrollContainer, 'addEventListener').mockImplementation((event, callback) => {
        if (event === 'scrollend') {
          scrollendCallback = callback as () => void;
        }
      });

      // Execute
      const result = scrollToIssue('1001', 'user-story');

      // Assert - 1st call (上端)
      expect(result).toBe(true);
      expect(wrapperScrollMock).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'start'
      });

      // Assert - scrollend後に2nd call (中央)
      scrollendCallback!();
      expect(wrapperScrollMock).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'center'
      });
      expect(wrapperScrollMock).toHaveBeenCalledTimes(2);
      expect(storyScrollMock).not.toHaveBeenCalled(); // wrapperをスクロール、story自体はスクロールしない

      addEventListenerSpy.mockRestore();
    });

    it.skip('Taskの場合は親のepic-version-wrapperを2段階スクロールする', () => {
      // Setup - スクロールコンテナも作成
      const scrollContainer = document.createElement('div');
      scrollContainer.className = 'triple-split-layout__center';

      const epicVersionWrapper = document.createElement('div');
      epicVersionWrapper.className = 'epic-version-wrapper';

      const taskDiv = document.createElement('div');
      taskDiv.setAttribute('data-task', '2001');
      taskDiv.className = 'task';

      epicVersionWrapper.appendChild(taskDiv);
      scrollContainer.appendChild(epicVersionWrapper);
      document.body.appendChild(scrollContainer);

      const wrapperScrollMock = vi.fn();
      epicVersionWrapper.scrollIntoView = wrapperScrollMock;

      // scrollendイベントをシミュレート
      let scrollendCallback: (() => void) | null = null;
      const addEventListenerSpy = vi.spyOn(scrollContainer, 'addEventListener').mockImplementation((event, callback) => {
        if (event === 'scrollend') {
          scrollendCallback = callback as () => void;
        }
      });

      // Execute
      const result = scrollToIssue('2001', 'task');

      // Assert - 1st call (上端)
      expect(result).toBe(true);
      expect(wrapperScrollMock).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'start'
      });

      // Assert - scrollend後に2nd call
      scrollendCallback!();
      expect(wrapperScrollMock).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'center'
      });
      expect(wrapperScrollMock).toHaveBeenCalledTimes(2);

      addEventListenerSpy.mockRestore();
    });

    it.skip('UserStoryがepic-version-wrapper外にある場合は2段階スクロール', () => {
      // Setup - スクロールコンテナも作成
      const scrollContainer = document.createElement('div');
      scrollContainer.className = 'triple-split-layout__center';

      const storyDiv = document.createElement('div');
      storyDiv.setAttribute('data-story', '3001');
      storyDiv.className = 'user-story';

      scrollContainer.appendChild(storyDiv);
      document.body.appendChild(scrollContainer);

      const scrollIntoViewMock = vi.fn();
      storyDiv.scrollIntoView = scrollIntoViewMock;

      // scrollendイベントをシミュレート
      let scrollendCallback: (() => void) | null = null;
      const addEventListenerSpy = vi.spyOn(scrollContainer, 'addEventListener').mockImplementation((event, callback) => {
        if (event === 'scrollend') {
          scrollendCallback = callback as () => void;
        }
      });

      // Execute
      const result = scrollToIssue('3001', 'user-story');

      // Assert - 1st call (上端)
      expect(result).toBe(true);
      expect(scrollIntoViewMock).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'start'
      });

      // Assert - scrollend後に2nd call
      scrollendCallback!();
      expect(scrollIntoViewMock).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'center'
      });
      expect(scrollIntoViewMock).toHaveBeenCalledTimes(2);

      addEventListenerSpy.mockRestore();
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

      // Assert - immediately after
      expect(epicDiv.classList.contains('search-highlight')).toBe(true);

      // Assert - after 3 seconds
      vi.advanceTimersByTime(3000);
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
