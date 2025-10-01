// Pragmatic Drag and Drop のインポート
import { draggable, dropTargetForElements, monitorForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { combine } from '@atlaskit/pragmatic-drag-and-drop/combine';

console.log('✅ Pragmatic Drag and Drop loaded');

// ユニークなインスタンスID
const instanceId = Symbol('nested-grid-test');

// DOM要素をスワップする汎用関数（同じ親要素内のみ）
function swapElements(sourceEl, targetEl) {
    // 同じ親要素内でのみスワップを許可
    if (sourceEl.parentElement !== targetEl.parentElement) {
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

// DOM要素を別の親要素に移動する関数
function moveElement(sourceEl, targetEl) {
    // targetEl と同じ親に移動
    const targetParent = targetEl.parentElement;

    if (!targetParent) {
        console.warn('⚠️ Target element has no parent');
        return false;
    }

    // targetEl の直後に挿入
    if (targetEl.nextSibling) {
        targetParent.insertBefore(sourceEl, targetEl.nextSibling);
    } else {
        targetParent.appendChild(sourceEl);
    }

    console.log('🚀 Element moved to different parent successfully');
    return true;
}

// Addボタンを常に末尾に移動する関数
function ensureAddButtonsAtEnd() {
    // Feature の Add ボタンを末尾に移動
    document.querySelectorAll('[data-add-button="feature"]').forEach(button => {
        const parent = button.parentElement;
        if (parent && parent.lastElementChild !== button) {
            parent.appendChild(button);
        }
    });

    // Epic の Add ボタンを Grid の末尾に移動
    const epicButton = document.querySelector('[data-add-button="epic"]');
    const grid = document.querySelector('.epic-version-grid');

    if (epicButton && grid && grid.lastElementChild !== epicButton) {
        grid.appendChild(epicButton);
    }

    // Version の Add ボタンは No Version セル内に固定されているため、移動不要
}

// 各レベルのドラッグ可能要素とドロップターゲットを設定
function setupDragAndDrop() {
    // Level 1: Epic/Version Add Buttons は dropTarget として登録しない
    // これらは新規作成用ボタンであり、既存カードのドロップ先ではない

    // Level 2: Feature Cards
    document.querySelectorAll('.feature-card').forEach(el => {
        const featureId = el.dataset.feature;
        const isAddButton = el.dataset.addButton;

        // Addボタンは dropTarget のみ (draggable にはしない)
        if (isAddButton) {
            dropTargetForElements({
                element: el,
                getData: () => ({ featureId: 'add-button' }),
                getIsSticky: () => true,
                canDrop: ({ source }) =>
                    source.data.instanceId === instanceId &&
                    source.data.type === 'feature-card',
                onDragEnter: () => el.classList.add('over'),
                onDragLeave: () => el.classList.remove('over'),
                onDrop: () => el.classList.remove('over'),
            });
            return;
        }

        // 通常のFeatureカードは draggable + dropTarget
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

            // 同じ親要素内ならスワップ、異なる親ならば移動
            const swapped = swapElements(sourceEl, targetEl);

            if (swapped) {
                console.log('🎉 Swap complete!', {
                    sourceId: sourceEl.dataset.feature || sourceEl.dataset.story || sourceEl.dataset.task || sourceEl.dataset.test || sourceEl.dataset.bug,
                    targetId: targetEl.dataset.feature || targetEl.dataset.story || targetEl.dataset.task || targetEl.dataset.test || targetEl.dataset.bug
                });
            } else {
                // スワップできなかった場合は移動を試みる
                const moved = moveElement(sourceEl, targetEl);

                if (moved) {
                    console.log('🎉 Move complete!', {
                        sourceId: sourceEl.dataset.feature || sourceEl.dataset.story || sourceEl.dataset.task || sourceEl.dataset.test || sourceEl.dataset.bug,
                        targetId: targetEl.dataset.feature || targetEl.dataset.story || targetEl.dataset.task || targetEl.dataset.test || targetEl.dataset.bug,
                        newParent: targetEl.parentElement
                    });
                } else {
                    console.warn('⚠️ Neither swap nor move was possible');
                }
            }

            // ドロップ完了後、すべてのAddボタンを末尾に移動
            ensureAddButtonsAtEnd();
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
