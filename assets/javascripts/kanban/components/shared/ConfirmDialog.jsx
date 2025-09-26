import React, { useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import Button from './Button';
import './ConfirmDialog.scss';

/**
 * Confirm Dialog Component
 * 確認ダイアログを表示するコンポーネント
 *
 * @param {Object} props
 * @param {boolean} props.isOpen - ダイアログ表示状態
 * @param {Function} props.onConfirm - 確認時のコールバック
 * @param {Function} props.onCancel - キャンセル時のコールバック
 * @param {string} props.title - ダイアログタイトル
 * @param {string|React.ReactNode} props.message - 確認メッセージ
 * @param {string} props.confirmText - 確認ボタンテキスト
 * @param {string} props.cancelText - キャンセルボタンテキスト
 * @param {'info'|'warning'|'danger'} props.variant - ダイアログの種類
 * @param {boolean} props.loading - 処理中状態
 * @param {boolean} props.closeOnEscape - Escキーで閉じるか
 * @param {boolean} props.closeOnBackdrop - 背景クリックで閉じるか
 * @param {string} props.className - 追加CSSクラス
 */
const ConfirmDialog = ({
  isOpen = false,
  onConfirm,
  onCancel,
  title,
  message,
  confirmText = 'OK',
  cancelText = 'Cancel',
  variant = 'info',
  loading = false,
  closeOnEscape = true,
  closeOnBackdrop = false,
  className = '',
  ...props
}) => {
  const dialogRef = useRef(null);
  const confirmButtonRef = useRef(null);

  // ダイアログが開いた時にフォーカスを設定
  useEffect(() => {
    if (isOpen && confirmButtonRef.current) {
      confirmButtonRef.current.focus();
    }
  }, [isOpen]);

  // Escキー処理
  useEffect(() => {
    if (!isOpen || !closeOnEscape) return;

    const handleKeyDown = (event) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        onCancel?.();
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, closeOnEscape, onCancel]);

  // フォーカストラップ
  useEffect(() => {
    if (!isOpen) return;

    const dialog = dialogRef.current;
    if (!dialog) return;

    const focusableElements = dialog.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );

    const firstElement = focusableElements[0];
    const lastElement = focusableElements[focusableElements.length - 1];

    const handleTabKey = (event) => {
      if (event.key !== 'Tab') return;

      if (event.shiftKey) {
        if (document.activeElement === firstElement) {
          event.preventDefault();
          lastElement?.focus();
        }
      } else {
        if (document.activeElement === lastElement) {
          event.preventDefault();
          firstElement?.focus();
        }
      }
    };

    document.addEventListener('keydown', handleTabKey);
    return () => document.removeEventListener('keydown', handleTabKey);
  }, [isOpen]);

  // 背景クリック処理
  const handleBackdropClick = (event) => {
    if (event.target === event.currentTarget && closeOnBackdrop) {
      onCancel?.();
    }
  };

  // 確認処理
  const handleConfirm = async () => {
    try {
      await onConfirm?.();
    } catch (error) {
      console.error('Confirm dialog error:', error);
    }
  };

  // キャンセル処理
  const handleCancel = () => {
    onCancel?.();
  };

  // バリアント別のアイコン取得
  const getVariantIcon = () => {
    switch (variant) {
      case 'danger':
        return 'icon-alert-triangle';
      case 'warning':
        return 'icon-alert-circle';
      case 'info':
      default:
        return 'icon-help-circle';
    }
  };

  // バリアント別の確認ボタンスタイル取得
  const getConfirmButtonVariant = () => {
    switch (variant) {
      case 'danger':
        return 'danger';
      case 'warning':
        return 'warning';
      case 'info':
      default:
        return 'primary';
    }
  };

  if (!isOpen) return null;

  const dialogContent = (
    <div
      className={`confirm_dialog_overlay ${className}`}
      onClick={handleBackdropClick}
      role="presentation"
    >
      <div
        ref={dialogRef}
        className={`confirm_dialog confirm_dialog_${variant}`}
        role="alertdialog"
        aria-modal="true"
        aria-labelledby={title ? 'confirm-dialog-title' : undefined}
        aria-describedby="confirm-dialog-message"
        {...props}
      >
        {/* アイコン */}
        <div className="confirm_dialog_icon">
          <i className={getVariantIcon()} />
        </div>

        {/* コンテンツ */}
        <div className="confirm_dialog_content">
          {/* タイトル */}
          {title && (
            <h3 id="confirm-dialog-title" className="confirm_dialog_title">
              {title}
            </h3>
          )}

          {/* メッセージ */}
          <div id="confirm-dialog-message" className="confirm_dialog_message">
            {message}
          </div>
        </div>

        {/* ボタン */}
        <div className="confirm_dialog_actions">
          <Button
            variant="secondary"
            onClick={handleCancel}
            disabled={loading}
          >
            {cancelText}
          </Button>

          <Button
            ref={confirmButtonRef}
            variant={getConfirmButtonVariant()}
            onClick={handleConfirm}
            loading={loading}
            disabled={loading}
          >
            {confirmText}
          </Button>
        </div>
      </div>
    </div>
  );

  // body直下にポータルで描画
  return createPortal(dialogContent, document.body);
};

export default ConfirmDialog;