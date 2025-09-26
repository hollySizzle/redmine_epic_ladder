import React, { createContext, useContext, useState, useCallback } from 'react';
import { createPortal } from 'react-dom';
import Toast from './Toast';

/**
 * Toast Context
 * Toast通知システムの状態管理
 */
const ToastContext = createContext(null);

/**
 * Toast Instance型定義
 * @typedef {Object} ToastInstance
 * @property {string} id - 一意識別子
 * @property {'success'|'error'|'warning'|'info'} type - 通知種別
 * @property {string|React.ReactNode} message - 表示メッセージ
 * @property {number} duration - 表示時間（ミリ秒）
 * @property {boolean} autoClose - 自動消失設定
 * @property {Object} action - アクションボタン設定
 * @property {number} createdAt - 作成時刻
 */

/**
 * Toast Options型定義
 * @typedef {Object} ToastOptions
 * @property {'success'|'error'|'warning'|'info'} type - 通知種別
 * @property {string|React.ReactNode} message - 表示メッセージ
 * @property {number} duration - 表示時間（ミリ秒）
 * @property {boolean} autoClose - 自動消失設定
 * @property {Object} action - アクションボタン設定
 */

/**
 * ToastManager Provider
 * Toast通知システムを管理するプロバイダー
 *
 * @param {Object} props
 * @param {React.ReactNode} props.children - 子コンポーネント
 * @param {number} props.maxToasts - 最大表示数
 * @param {Object} props.defaultDuration - デフォルト表示時間設定
 * @param {'top-right'|'top-left'|'bottom-right'|'bottom-left'|'top-center'|'bottom-center'} props.position - 表示位置
 */
const ToastProvider = ({
  children,
  maxToasts = 5,
  defaultDuration = {
    success: 3000,
    error: 5000,
    warning: 4000,
    info: 3000
  },
  position = 'top-right'
}) => {
  const [toasts, setToasts] = useState([]);

  // 一意IDを生成
  const generateId = useCallback(() => {
    return `toast-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }, []);

  // Toast追加
  const showToast = useCallback((options) => {
    const id = generateId();
    const duration = options.duration ?? defaultDuration[options.type] ?? 3000;

    const toastInstance = {
      id,
      type: options.type || 'info',
      message: options.message,
      duration,
      autoClose: options.autoClose !== false,
      action: options.action,
      createdAt: Date.now(),
      ...options
    };

    setToasts((prevToasts) => {
      const newToasts = [toastInstance, ...prevToasts];
      // 最大表示数を超える場合は古いものから削除
      return newToasts.slice(0, maxToasts);
    });

    return id;
  }, [generateId, defaultDuration, maxToasts]);

  // Toast削除
  const removeToast = useCallback((id) => {
    setToasts((prevToasts) => prevToasts.filter((toast) => toast.id !== id));
  }, []);

  // 全Toast削除
  const clearAllToasts = useCallback(() => {
    setToasts([]);
  }, []);

  // 便利メソッド群
  const showSuccess = useCallback((message, options = {}) => {
    return showToast({ ...options, type: 'success', message });
  }, [showToast]);

  const showError = useCallback((message, options = {}) => {
    return showToast({ ...options, type: 'error', message });
  }, [showToast]);

  const showWarning = useCallback((message, options = {}) => {
    return showToast({ ...options, type: 'warning', message });
  }, [showToast]);

  const showInfo = useCallback((message, options = {}) => {
    return showToast({ ...options, type: 'info', message });
  }, [showToast]);

  // Context値
  const contextValue = {
    toasts,
    showToast,
    removeToast,
    clearAllToasts,
    showSuccess,
    showError,
    showWarning,
    showInfo
  };

  // 位置クラス計算
  const getPositionClass = () => {
    return `toast_container toast_container_${position.replace('-', '_')}`;
  };

  return (
    <ToastContext.Provider value={contextValue}>
      {children}

      {/* Toast Container - Portal経由で描画 */}
      {toasts.length > 0 && createPortal(
        <div className={getPositionClass()}>
          {toasts.map((toast) => (
            <Toast
              key={toast.id}
              type={toast.type}
              message={toast.message}
              duration={toast.duration}
              autoClose={toast.autoClose}
              action={toast.action}
              onClose={() => removeToast(toast.id)}
            />
          ))}
        </div>,
        document.body
      )}
    </ToastContext.Provider>
  );
};

/**
 * useToast Hook
 * Toast通知機能を利用するためのカスタムフック
 *
 * @returns {Object} Toast操作用のメソッド群
 * @returns {Function} showToast - Toast表示
 * @returns {Function} removeToast - Toast削除
 * @returns {Function} clearAllToasts - 全Toast削除
 * @returns {Function} showSuccess - 成功通知
 * @returns {Function} showError - エラー通知
 * @returns {Function} showWarning - 警告通知
 * @returns {Function} showInfo - 情報通知
 * @returns {Array} toasts - 現在のToast一覧
 */
const useToast = () => {
  const context = useContext(ToastContext);

  if (!context) {
    throw new Error('useToast must be used within a ToastProvider');
  }

  return context;
};

// Toast Container位置別スタイル
const ToastContainerStyle = `
.toast_container {
  position: fixed;
  z-index: 1050;
  pointer-events: none;
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-height: 100vh;
  overflow: hidden;
}

.toast_container_top_right {
  top: 20px;
  right: 20px;
}

.toast_container_top_left {
  top: 20px;
  left: 20px;
}

.toast_container_bottom_right {
  bottom: 20px;
  right: 20px;
  flex-direction: column-reverse;
}

.toast_container_bottom_left {
  bottom: 20px;
  left: 20px;
  flex-direction: column-reverse;
}

.toast_container_top_center {
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
}

.toast_container_bottom_center {
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  flex-direction: column-reverse;
}

.toast_container .toast {
  position: relative;
  top: auto;
  right: auto;
  left: auto;
  bottom: auto;
  margin: 0;
  pointer-events: all;
}

@media (max-width: 480px) {
  .toast_container_top_right,
  .toast_container_top_left,
  .toast_container_top_center {
    left: 20px;
    right: 20px;
    top: 20px;
    transform: none;
  }

  .toast_container_bottom_right,
  .toast_container_bottom_left,
  .toast_container_bottom_center {
    left: 20px;
    right: 20px;
    bottom: 20px;
    transform: none;
  }
}
`;

// スタイルを動的に追加
if (typeof document !== 'undefined' && !document.getElementById('toast-container-styles')) {
  const style = document.createElement('style');
  style.id = 'toast-container-styles';
  style.textContent = ToastContainerStyle;
  document.head.appendChild(style);
}

export { ToastProvider, useToast };
export default ToastProvider;