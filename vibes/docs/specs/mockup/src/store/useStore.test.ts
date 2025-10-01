import { describe, it, expect, beforeEach } from 'vitest';
import { useStore } from './useStore';
import { mockCells } from '../mockData';

describe('useStore - Feature reordering', () => {
  beforeEach(() => {
    // ストアを初期データでリセット
    useStore.setState({ cells: JSON.parse(JSON.stringify(mockCells)) });
  });

  it('should reorder features within the same cell', () => {
    const store = useStore.getState();
    const initialCell = store.cells.find(c => c.epicId === 'epic1' && c.versionId === 'v1');

    expect(initialCell?.features[0].id).toBe('f1');
    expect(initialCell?.features[1].id).toBe('f2');

    // f2 を f1 の位置に移動
    store.reorderFeatures('f2', 'f1');

    const updatedCell = useStore.getState().cells.find(c => c.epicId === 'epic1' && c.versionId === 'v1');

    expect(updatedCell?.features[0].id).toBe('f2');
    expect(updatedCell?.features[1].id).toBe('f1');
  });

  it('should move feature to different cell', () => {
    const store = useStore.getState();

    const sourceCell = store.cells.find(c => c.epicId === 'epic1' && c.versionId === 'v1');
    const targetCell = store.cells.find(c => c.epicId === 'epic1' && c.versionId === 'v2');

    expect(sourceCell?.features.length).toBe(2); // f1, f2
    expect(targetCell?.features.length).toBe(1); // f3

    // f2 を f3 のセルに移動
    store.reorderFeatures('f2', 'f3');

    const updatedSourceCell = useStore.getState().cells.find(c => c.epicId === 'epic1' && c.versionId === 'v1');
    const updatedTargetCell = useStore.getState().cells.find(c => c.epicId === 'epic1' && c.versionId === 'v2');

    expect(updatedSourceCell?.features.length).toBe(1); // f1 のみ
    expect(updatedTargetCell?.features.length).toBe(2); // f3, f2
    expect(updatedTargetCell?.features[1].id).toBe('f2'); // f3 の後に f2
  });

  it('should move feature to empty cell using add button', () => {
    const store = useStore.getState();

    const sourceCell = store.cells.find(c => c.epicId === 'epic2' && c.versionId === 'v2');
    const targetCell = store.cells.find(c => c.epicId === 'epic2' && c.versionId === 'v3');

    expect(sourceCell?.features.length).toBe(1); // f4
    expect(targetCell?.features.length).toBe(0); // 空

    // f4 を空のセルに移動（Addボタン経由）
    store.reorderFeatures('f4', 'add-button', {
      isAddButton: true,
      epicId: 'epic2',
      versionId: 'v3'
    });

    const updatedSourceCell = useStore.getState().cells.find(c => c.epicId === 'epic2' && c.versionId === 'v2');
    const updatedTargetCell = useStore.getState().cells.find(c => c.epicId === 'epic2' && c.versionId === 'v3');

    expect(updatedSourceCell?.features.length).toBe(0); // 空になった
    expect(updatedTargetCell?.features.length).toBe(1); // f4 が追加された
    expect(updatedTargetCell?.features[0].id).toBe('f4');
  });
});

describe('useStore - UserStory reordering', () => {
  beforeEach(() => {
    // ストアを初期データでリセット
    useStore.setState({ cells: JSON.parse(JSON.stringify(mockCells)) });
  });

  it('should reorder user stories within the same feature', () => {
    const store = useStore.getState();

    // f4には us4 が1つしかないので、テスト用に追加のstoryを手動で追加
    const cell = store.cells.find(c => c.epicId === 'epic2' && c.versionId === 'v2');
    const feature = cell?.features.find(f => f.id === 'f4');

    // us4a を追加
    feature?.stories.push({
      id: 'us4a',
      title: 'US#202 テスト用Story',
      status: 'open',
      tasks: [],
      tests: [],
      bugs: []
    });

    expect(feature?.stories[0].id).toBe('us4');
    expect(feature?.stories[1].id).toBe('us4a');

    // us4a を us4 の位置に移動
    store.reorderUserStories('us4a', 'us4');

    const updatedFeature = useStore.getState().cells
      .flatMap(c => c.features)
      .find(f => f.id === 'f4');

    expect(updatedFeature?.stories[0].id).toBe('us4a');
    expect(updatedFeature?.stories[1].id).toBe('us4');
  });

  it('should move user story to different feature', () => {
    const store = useStore.getState();

    const sourceFeature = store.cells.flatMap(c => c.features).find(f => f.id === 'f1');
    const targetFeature = store.cells.flatMap(c => c.features).find(f => f.id === 'f2');

    expect(sourceFeature?.stories.length).toBe(1); // us1
    expect(targetFeature?.stories.length).toBe(1); // us2

    // us1 を f2 の us2 の後に移動
    store.reorderUserStories('us1', 'us2');

    const updatedSourceFeature = useStore.getState().cells.flatMap(c => c.features).find(f => f.id === 'f1');
    const updatedTargetFeature = useStore.getState().cells.flatMap(c => c.features).find(f => f.id === 'f2');

    expect(updatedSourceFeature?.stories.length).toBe(0); // 空になった
    expect(updatedTargetFeature?.stories.length).toBe(2); // us2, us1
    expect(updatedTargetFeature?.stories[1].id).toBe('us1');
  });
});

describe('useStore - Task reordering', () => {
  beforeEach(() => {
    // ストアを初期データでリセット
    useStore.setState({ cells: JSON.parse(JSON.stringify(mockCells)) });
  });

  it('should reorder tasks within the same user story', () => {
    const store = useStore.getState();

    const story = store.cells
      .flatMap(c => c.features)
      .flatMap(f => f.stories)
      .find(s => s.id === 'us1');

    expect(story?.tasks[0].id).toBe('t1');
    expect(story?.tasks[1].id).toBe('t2');

    // t2 を t1 の位置に移動
    store.reorderTasks('t2', 't1');

    const updatedStory = useStore.getState().cells
      .flatMap(c => c.features)
      .flatMap(f => f.stories)
      .find(s => s.id === 'us1');

    expect(updatedStory?.tasks[0].id).toBe('t2');
    expect(updatedStory?.tasks[1].id).toBe('t1');
  });

  it('should move task to different user story', () => {
    const store = useStore.getState();

    const sourceStory = store.cells.flatMap(c => c.features).flatMap(f => f.stories).find(s => s.id === 'us1');
    const targetStory = store.cells.flatMap(c => c.features).flatMap(f => f.stories).find(s => s.id === 'us2');

    expect(sourceStory?.tasks.length).toBe(2); // t1, t2
    expect(targetStory?.tasks.length).toBe(1); // t3

    // t2 を us2 の t3 の後に移動
    store.reorderTasks('t2', 't3');

    const updatedSourceStory = useStore.getState().cells.flatMap(c => c.features).flatMap(f => f.stories).find(s => s.id === 'us1');
    const updatedTargetStory = useStore.getState().cells.flatMap(c => c.features).flatMap(f => f.stories).find(s => s.id === 'us2');

    expect(updatedSourceStory?.tasks.length).toBe(1); // t1 のみ
    expect(updatedTargetStory?.tasks.length).toBe(2); // t3, t2
    expect(updatedTargetStory?.tasks[1].id).toBe('t2');
  });
});

describe('useStore - Test reordering', () => {
  beforeEach(() => {
    // ストアを初期データでリセット
    useStore.setState({ cells: JSON.parse(JSON.stringify(mockCells)) });
  });

  it('should reorder tests within the same user story', () => {
    const store = useStore.getState();

    // us1にはtest1が1つあるので、テスト用にもう1つ追加
    const story = store.cells
      .flatMap(c => c.features)
      .flatMap(f => f.stories)
      .find(s => s.id === 'us1');

    story?.tests.push({
      id: 'test2',
      title: 'E2Eテスト作成',
      status: 'open'
    });

    expect(story?.tests[0].id).toBe('test1');
    expect(story?.tests[1].id).toBe('test2');

    // test2 を test1 の位置に移動
    store.reorderTests('test2', 'test1');

    const updatedStory = useStore.getState().cells
      .flatMap(c => c.features)
      .flatMap(f => f.stories)
      .find(s => s.id === 'us1');

    expect(updatedStory?.tests[0].id).toBe('test2');
    expect(updatedStory?.tests[1].id).toBe('test1');
  });

  it('should move test to different user story', () => {
    const store = useStore.getState();

    const sourceStory = store.cells.flatMap(c => c.features).flatMap(f => f.stories).find(s => s.id === 'us1');
    const targetStory = store.cells.flatMap(c => c.features).flatMap(f => f.stories).find(s => s.id === 'us2');

    // us2にもtestを追加
    targetStory?.tests.push({
      id: 'test3',
      title: '一覧画面テスト',
      status: 'open'
    });

    expect(sourceStory?.tests.length).toBe(1); // test1
    expect(targetStory?.tests.length).toBe(1); // test3

    // test1 を us2 の test3 の後に移動
    store.reorderTests('test1', 'test3');

    const updatedSourceStory = useStore.getState().cells.flatMap(c => c.features).flatMap(f => f.stories).find(s => s.id === 'us1');
    const updatedTargetStory = useStore.getState().cells.flatMap(c => c.features).flatMap(f => f.stories).find(s => s.id === 'us2');

    expect(updatedSourceStory?.tests.length).toBe(0); // 空になった
    expect(updatedTargetStory?.tests.length).toBe(2); // test3, test1
    expect(updatedTargetStory?.tests[1].id).toBe('test1');
  });
});

describe('useStore - Bug reordering', () => {
  beforeEach(() => {
    // ストアを初期データでリセット
    useStore.setState({ cells: JSON.parse(JSON.stringify(mockCells)) });
  });

  it('should reorder bugs within the same user story', () => {
    const store = useStore.getState();

    // us1にはb1が1つあるので、テスト用にもう1つ追加
    const story = store.cells
      .flatMap(c => c.features)
      .flatMap(f => f.stories)
      .find(s => s.id === 'us1');

    story?.bugs.push({
      id: 'b2',
      title: 'UI表示崩れ修正',
      status: 'open'
    });

    expect(story?.bugs[0].id).toBe('b1');
    expect(story?.bugs[1].id).toBe('b2');

    // b2 を b1 の位置に移動
    store.reorderBugs('b2', 'b1');

    const updatedStory = useStore.getState().cells
      .flatMap(c => c.features)
      .flatMap(f => f.stories)
      .find(s => s.id === 'us1');

    expect(updatedStory?.bugs[0].id).toBe('b2');
    expect(updatedStory?.bugs[1].id).toBe('b1');
  });

  it('should move bug to different user story', () => {
    const store = useStore.getState();

    const sourceStory = store.cells.flatMap(c => c.features).flatMap(f => f.stories).find(s => s.id === 'us1');
    const targetStory = store.cells.flatMap(c => c.features).flatMap(f => f.stories).find(s => s.id === 'us2');

    // us2にもbugを追加
    targetStory?.bugs.push({
      id: 'b3',
      title: 'データ取得エラー',
      status: 'open'
    });

    expect(sourceStory?.bugs.length).toBe(1); // b1
    expect(targetStory?.bugs.length).toBe(1); // b3

    // b1 を us2 の b3 の後に移動
    store.reorderBugs('b1', 'b3');

    const updatedSourceStory = useStore.getState().cells.flatMap(c => c.features).flatMap(f => f.stories).find(s => s.id === 'us1');
    const updatedTargetStory = useStore.getState().cells.flatMap(c => c.features).flatMap(f => f.stories).find(s => s.id === 'us2');

    expect(updatedSourceStory?.bugs.length).toBe(0); // 空になった
    expect(updatedTargetStory?.bugs.length).toBe(2); // b3, b1
    expect(updatedTargetStory?.bugs[1].id).toBe('b1');
  });
});

describe('useStore - Error cases', () => {
  beforeEach(() => {
    // ストアを初期データでリセット
    useStore.setState({ cells: JSON.parse(JSON.stringify(mockCells)) });
  });

  it('should not fail when moving non-existent feature', () => {
    const store = useStore.getState();
    const initialState = JSON.stringify(store.cells);

    // 存在しないfeatureを移動しようとする
    store.reorderFeatures('non-existent-feature', 'f1');

    // ストアの状態が変わっていないことを確認
    expect(JSON.stringify(useStore.getState().cells)).toBe(initialState);
  });

  it('should not fail when moving to non-existent target feature', () => {
    const store = useStore.getState();
    const cell = store.cells.find(c => c.epicId === 'epic1' && c.versionId === 'v1');
    const initialFeatureCount = cell?.features.length;

    // 存在しないターゲットに移動しようとする
    store.reorderFeatures('f1', 'non-existent-target');

    const updatedCell = useStore.getState().cells.find(c => c.epicId === 'epic1' && c.versionId === 'v1');

    // セル内のfeature数が変わっていないことを確認
    expect(updatedCell?.features.length).toBe(initialFeatureCount);
  });

  it('should not fail when moving non-existent user story', () => {
    const store = useStore.getState();
    const initialState = JSON.stringify(store.cells);

    // 存在しないstoryを移動しようとする
    store.reorderUserStories('non-existent-story', 'us1');

    // ストアの状態が変わっていないことを確認
    expect(JSON.stringify(useStore.getState().cells)).toBe(initialState);
  });

  it('should not fail when moving non-existent task', () => {
    const store = useStore.getState();
    const initialState = JSON.stringify(store.cells);

    // 存在しないtaskを移動しようとする
    store.reorderTasks('non-existent-task', 't1');

    // ストアの状態が変わっていないことを確認
    expect(JSON.stringify(useStore.getState().cells)).toBe(initialState);
  });

  it('should handle empty arrays gracefully', () => {
    const store = useStore.getState();

    // 空のセルを作成
    const emptyCell = store.cells.find(c => c.epicId === 'epic1' && c.versionId === 'v3');
    expect(emptyCell?.features.length).toBe(0);

    // 空のセルに対して操作しても問題ないことを確認
    store.reorderFeatures('f1', 'add-button', {
      isAddButton: true,
      epicId: 'epic1',
      versionId: 'v3'
    });

    const updatedCell = useStore.getState().cells.find(c => c.epicId === 'epic1' && c.versionId === 'v3');

    // f1が移動していることを確認
    expect(updatedCell?.features.length).toBe(1);
    expect(updatedCell?.features[0].id).toBe('f1');
  });

  it('should preserve other cells when moving features', () => {
    const store = useStore.getState();

    const otherCell = store.cells.find(c => c.epicId === 'epic2' && c.versionId === 'v2');
    const initialOtherCellState = JSON.stringify(otherCell);

    // epic1のfeatureを移動
    store.reorderFeatures('f1', 'f2');

    // 他のセル(epic2)が影響を受けていないことを確認
    const updatedOtherCell = useStore.getState().cells.find(c => c.epicId === 'epic2' && c.versionId === 'v2');
    expect(JSON.stringify(updatedOtherCell)).toBe(initialOtherCellState);
  });
});
