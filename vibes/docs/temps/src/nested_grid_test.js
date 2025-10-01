// Pragmatic Drag and Drop のインポート
import { draggable, dropTargetForElements, monitorForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { combine } from '@atlaskit/pragmatic-drag-and-drop/combine';

console.log('✅ Pragmatic Drag and Drop loaded');

// ユニークなインスタンスID
const instanceId = Symbol('nested-grid-test');

// DOM要素をスワップする汎用関数
function swapElements(sourceEl, targetEl) {
    // 同じ親要素内でのみスワップを許可
    if (sourceEl.parentElement !== targetEl.parentElement) {
        console.warn('⚠️ Cannot swap elements with different parents');
        return false;
    }

    const parent = sourceEl.parentElement;
    const sourceIndex = Array.from(parent.children).indexOf(sourceEl);
    const targetIndex = Array.from(parent.children).indexOf(targetEl);

    if (sourceIndex === targetIndex) {
        return false;
    }

    // 位置関係に応じて挿入
    if (sourceIndex < targetIndex) {
        // source が target より前にある場合
        parent.insertBefore(targetEl, sourceEl);
        parent.insertBefore(sourceEl, parent.children[targetIndex]);
    } else {
        // source が target より後にある場合
        parent.insertBefore(sourceEl, targetEl);
        parent.insertBefore(targetEl, parent.children[sourceIndex]);
    }

    console.log('✨ Elements swapped successfully');
    return true;
}

// 各レベルのドラッグ可能要素とドロップターゲットを設定
function setupDragAndDrop() {
    // Level 2: Feature Cards
    document.querySelectorAll('.feature-card').forEach(el => {
        const featureId = el.dataset.feature;

        combine(
            draggable({
                element: el,
                getInitialData: () => ({
                    type: 'feature-card',
                    featureId,
                    instanceId
                }),
                onDragStart: () => el.classList.add('dragging'),
                onDrop: () => el.classList.remove('dragging'),
            }),
            dropTargetForElements({
                element: el,
                getData: () => ({ featureId }),
                getIsSticky: () => true,
                canDrop: ({ source }) =>
                    source.data.instanceId === instanceId &&
                    source.data.type === 'feature-card' &&
                    source.data.featureId !== featureId,
                onDragEnter: () => el.classList.add('over'),
                onDragLeave: () => el.classList.remove('over'),
                onDrop: () => el.classList.remove('over'),
            })
        );
    });

    // Level 3: User Stories
    document.querySelectorAll('.user-story').forEach(el => {
        const storyId = el.dataset.story;

        combine(
            draggable({
                element: el,
                getInitialData: () => ({
                    type: 'user-story',
                    storyId,
                    instanceId
                }),
                onDragStart: () => el.classList.add('dragging'),
                onDrop: () => el.classList.remove('dragging'),
            }),
            dropTargetForElements({
                element: el,
                getData: () => ({ storyId }),
                getIsSticky: () => true,
                canDrop: ({ source }) =>
                    source.data.instanceId === instanceId &&
                    source.data.type === 'user-story' &&
                    source.data.storyId !== storyId,
                onDragEnter: () => el.classList.add('over'),
                onDragLeave: () => el.classList.remove('over'),
                onDrop: () => el.classList.remove('over'),
            })
        );
    });

    // Level 4: Tasks
    document.querySelectorAll('.task-item').forEach(el => {
        const taskId = el.dataset.task;

        combine(
            draggable({
                element: el,
                getInitialData: () => ({
                    type: 'task',
                    taskId,
                    instanceId
                }),
                onDragStart: () => el.classList.add('dragging'),
                onDrop: () => el.classList.remove('dragging'),
            }),
            dropTargetForElements({
                element: el,
                getData: () => ({ taskId }),
                getIsSticky: () => true,
                canDrop: ({ source }) =>
                    source.data.instanceId === instanceId &&
                    source.data.type === 'task' &&
                    source.data.taskId !== taskId,
                onDragEnter: () => el.classList.add('over'),
                onDragLeave: () => el.classList.remove('over'),
                onDrop: () => el.classList.remove('over'),
            })
        );
    });

    // Level 4: Tests
    document.querySelectorAll('.test-item').forEach(el => {
        const testId = el.dataset.test;

        combine(
            draggable({
                element: el,
                getInitialData: () => ({
                    type: 'test',
                    testId,
                    instanceId
                }),
                onDragStart: () => el.classList.add('dragging'),
                onDrop: () => el.classList.remove('dragging'),
            }),
            dropTargetForElements({
                element: el,
                getData: () => ({ testId }),
                getIsSticky: () => true,
                canDrop: ({ source }) =>
                    source.data.instanceId === instanceId &&
                    source.data.type === 'test' &&
                    source.data.testId !== testId,
                onDragEnter: () => el.classList.add('over'),
                onDragLeave: () => el.classList.remove('over'),
                onDrop: () => el.classList.remove('over'),
            })
        );
    });

    // Level 4: Bugs
    document.querySelectorAll('.bug-item').forEach(el => {
        const bugId = el.dataset.bug;

        combine(
            draggable({
                element: el,
                getInitialData: () => ({
                    type: 'bug',
                    bugId,
                    instanceId
                }),
                onDragStart: () => el.classList.add('dragging'),
                onDrop: () => el.classList.remove('dragging'),
            }),
            dropTargetForElements({
                element: el,
                getData: () => ({ bugId }),
                getIsSticky: () => true,
                canDrop: ({ source }) =>
                    source.data.instanceId === instanceId &&
                    source.data.type === 'bug' &&
                    source.data.bugId !== bugId,
                onDragEnter: () => el.classList.add('over'),
                onDragLeave: () => el.classList.remove('over'),
                onDrop: () => el.classList.remove('over'),
            })
        );
    });

    // Monitor for all drag operations
    monitorForElements({
        canMonitor({ source }) {
            return source.data.instanceId === instanceId;
        },
        onDrop({ source, location }) {
            const destination = location.current.dropTargets[0];
            if (!destination) {
                console.log('❌ No drop target found');
                return;
            }

            // ソース要素とターゲット要素を取得
            const sourceEl = source.element;
            const targetEl = destination.element;

            console.log('✅ Drop detected:', {
                type: source.data.type,
                source: source.data,
                destination: destination.data
            });

            // DOM要素をスワップ
            const swapped = swapElements(sourceEl, targetEl);

            if (swapped) {
                console.log('🎉 Swap complete!', {
                    sourceId: sourceEl.dataset.feature || sourceEl.dataset.story || sourceEl.dataset.task || sourceEl.dataset.test || sourceEl.dataset.bug,
                    targetId: targetEl.dataset.feature || targetEl.dataset.story || targetEl.dataset.task || targetEl.dataset.test || targetEl.dataset.bug
                });
            }
        }
    });
}

// ページロード時に初期化
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupDragAndDrop);
} else {
    setupDragAndDrop();
}

console.log('🎯 Nested Grid Test initialized with 4 levels');
