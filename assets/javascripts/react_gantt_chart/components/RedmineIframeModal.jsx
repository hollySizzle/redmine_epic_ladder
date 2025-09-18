import React, { useRef, useEffect } from 'react';
import './RedmineIframeModal.scss';

/**
 * Redmineのチケット詳細をモーダルで表示するコンポーネント
 * （既存のモーダル機能をそのまま流用）
 */
const RedmineIframeModal = ({ taskId, onClose }) => {
  const modalRef = useRef(null);

  // モーダル外クリックで閉じる
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (modalRef.current && !modalRef.current.contains(event.target)) {
        onClose();
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [onClose]);

  // ESCキーで閉じる
  useEffect(() => {
    const handleEsc = (event) => {
      if (event.keyCode === 27) {
        onClose();
      }
    };

    document.addEventListener('keydown', handleEsc);
    return () => {
      document.removeEventListener('keydown', handleEsc);
    };
  }, [onClose]);

  if (!taskId) return null;

  return (
    <div className="redmine-iframe-modal-overlay">
      <div className="redmine-iframe-modal" ref={modalRef}>
        <div className="redmine-iframe-modal__header">
          <h3 className="redmine-iframe-modal__title">
            チケット #{taskId}
          </h3>
          <button
            className="redmine-iframe-modal__close"
            onClick={onClose}
            aria-label="閉じる"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
              <path d="M18 6L6 18M6 6l12 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
            </svg>
          </button>
        </div>
        <div className="redmine-iframe-modal__content">
          <iframe
            src={`/issues/${taskId}`}
            className="redmine-iframe-modal__iframe"
            title={`チケット #${taskId} の詳細`}
          />
        </div>
      </div>
    </div>
  );
};

export default RedmineIframeModal;