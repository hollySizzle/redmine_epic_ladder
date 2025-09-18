import React, { useEffect, useRef } from 'react';
import ReactDOM from 'react-dom';

/**
 * Ganttチャートを React のレンダリングツリー外に配置するポータルコンポーネント
 * これにより、React の再レンダリングによる影響を完全に回避する
 */
const GanttPortal = ({ children, containerId }) => {
  const containerRef = useRef(null);

  useEffect(() => {
    // ポータル用のコンテナを作成
    const container = document.createElement('div');
    container.id = containerId;
    container.style.width = '100%';
    container.style.height = '100%';
    
    // 現在のコンテナに追加
    if (containerRef.current) {
      containerRef.current.appendChild(container);
    }

    return () => {
      // クリーンアップ
      if (container.parentNode) {
        container.parentNode.removeChild(container);
      }
    };
  }, [containerId]);

  // コンテナが準備できたらポータルを作成
  const container = containerRef.current?.querySelector(`#${containerId}`);
  
  return (
    <>
      <div ref={containerRef} style={{ width: '100%', height: '100%' }} />
      {container && ReactDOM.createPortal(children, container)}
    </>
  );
};

export default GanttPortal;