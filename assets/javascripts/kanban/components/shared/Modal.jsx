import React, { useEffect, useCallback } from 'react';
import { createPortal } from 'react-dom';
import './Modal.scss';

/**
 * Modal Component
 * 汎用モーダルダイアログコンポーネント
 *
 * @param {Object} props
 * @param {boolean} props.isOpen - モーダル表示状態
 * @param {Function} props.onClose - クローズコールバック
 * @param {string} props.title - モーダルタイトル
 * @param {React.ReactNode} props.children - モーダルコンテンツ
 * @param {string} props.size - モーダルサイズ ('small'|'medium'|'large'|'fullscreen')
 * @param {boolean} props.closeOnEscape - Escキーで閉じるか
 * @param {boolean} props.closeOnBackdrop - 背景クリックで閉じるか
 * @param {string} props.className - 追加CSSクラス
 */
const Modal = ({
  isOpen = false,
  onClose,
  title,
  children,
  size = 'medium',
  closeOnEscape = true,
  closeOnBackdrop = true,
  className = '',
  ...props
}) => {
  // Escキーでの閉じる処理
  const handleKeyDown = useCallback((event) => {
    if (event.key === 'Escape' && closeOnEscape) {
      onClose?.();
    }
  }, [closeOnEscape, onClose]);

  // 背景クリックでの閉じる処理
  const handleBackdropClick = useCallback((event) => {
    if (event.target === event.currentTarget && closeOnBackdrop) {
      onClose?.();
    }
  }, [closeOnBackdrop, onClose]);

  // キーボードイベントの登録/削除
  useEffect(() => {
    if (isOpen) {
      document.addEventListener('keydown', handleKeyDown);
      document.body.classList.add('modal_open');
    }

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      document.body.classList.remove('modal_open');
    };
  }, [isOpen, handleKeyDown]);

  if (!isOpen) return null;

  const modalContent = (
    <div
      className={`modal_overlay ${className}`}
      onClick={handleBackdropClick}
      {...props}
    >
      <div className={`modal_container ${size}`}>
        {/* MODAL_HEADER */}
        <div className="modal_header">
          {title && (
            <h2 className="modal_title">{title}</h2>
          )}

          <button
            className="modal_close_btn"
            onClick={onClose}
            type="button"
            aria-label="Close modal"
          >
            <i className="icon-close" />
          </button>
        </div>

        {/* MODAL_CONTENT */}
        <div className="modal_content">
          {children}
        </div>
      </div>
    </div>
  );

  // ポータルを使用してbody直下にレンダリング
  return createPortal(modalContent, document.body);
};

export default Modal;