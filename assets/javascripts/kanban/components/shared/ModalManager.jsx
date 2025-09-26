import React, { createContext, useContext, useState, useCallback } from 'react';
import Modal from './Modal';
import ConfirmDialog from './ConfirmDialog';
import LoadingSpinner from './LoadingSpinner';

/**
 * Modal Context
 * モーダル管理システムの状態管理
 */
const ModalContext = createContext(null);

/**
 * Modal Instance型定義
 * @typedef {Object} ModalInstance
 * @property {string} id - 一意識別子
 * @property {React.ComponentType} component - モーダルコンポーネント
 * @property {Object} props - コンポーネントのProps
 * @property {number} zIndex - z-index値
 * @property {number} createdAt - 作成時刻
 * @property {Function} resolve - Promise解決関数（ConfirmDialog用）
 * @property {Function} reject - Promise拒否関数（ConfirmDialog用）
 */

/**
 * Confirm Options型定義
 * @typedef {Object} ConfirmOptions
 * @property {string} title - ダイアログタイトル
 * @property {string|React.ReactNode} message - 確認メッセージ
 * @property {string} confirmText - 確認ボタンテキスト
 * @property {string} cancelText - キャンセルボタンテキスト
 * @property {'info'|'warning'|'danger'} variant - ダイアログの種類
 */

/**
 * Alert Options型定義
 * @typedef {Object} AlertOptions
 * @property {string} title - ダイアログタイトル
 * @property {string|React.ReactNode} message - アラートメッセージ
 * @property {string} buttonText - ボタンテキスト
 * @property {'info'|'warning'|'danger'} type - アラートの種類
 */

/**
 * ModalManager Provider
 * モーダル表示を管理するプロバイダー
 *
 * @param {Object} props
 * @param {React.ReactNode} props.children - 子コンポーネント
 * @param {number} props.baseZIndex - ベースz-index値
 */
const ModalProvider = ({
  children,
  baseZIndex = 1050
}) => {
  const [modals, setModals] = useState([]);

  // 一意IDを生成
  const generateId = useCallback(() => {
    return `modal-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }, []);

  // z-index計算
  const getNextZIndex = useCallback(() => {
    return baseZIndex + modals.length * 10;
  }, [baseZIndex, modals.length]);

  // モーダル表示
  const showModal = useCallback((component, props = {}) => {
    const id = generateId();
    const zIndex = getNextZIndex();

    const modalInstance = {
      id,
      component,
      props,
      zIndex,
      createdAt: Date.now()
    };

    setModals((prevModals) => [...prevModals, modalInstance]);
    return id;
  }, [generateId, getNextZIndex]);

  // モーダル閉じる
  const closeModal = useCallback((id) => {
    setModals((prevModals) => {
      const modal = prevModals.find(m => m.id === id);
      if (modal && modal.reject) {
        modal.reject(new Error('Modal cancelled'));
      }
      return prevModals.filter(m => m.id !== id);
    });
  }, []);

  // 全モーダル閉じる
  const closeAllModals = useCallback(() => {
    setModals((prevModals) => {
      prevModals.forEach(modal => {
        if (modal.reject) {
          modal.reject(new Error('All modals cancelled'));
        }
      });
      return [];
    });
  }, []);

  // 確認ダイアログ表示（Promise返却）
  const showConfirm = useCallback((options) => {
    return new Promise((resolve, reject) => {
      const id = generateId();
      const zIndex = getNextZIndex();

      const confirmProps = {
        isOpen: true,
        title: options.title,
        message: options.message,
        confirmText: options.confirmText || 'OK',
        cancelText: options.cancelText || 'Cancel',
        variant: options.variant || 'info',
        onConfirm: () => {
          closeModal(id);
          resolve(true);
        },
        onCancel: () => {
          closeModal(id);
          resolve(false);
        }
      };

      const modalInstance = {
        id,
        component: ConfirmDialog,
        props: confirmProps,
        zIndex,
        createdAt: Date.now(),
        resolve,
        reject
      };

      setModals((prevModals) => [...prevModals, modalInstance]);
    });
  }, [generateId, getNextZIndex, closeModal]);

  // アラートダイアログ表示
  const showAlert = useCallback((message, type = 'info') => {
    return new Promise((resolve) => {
      const id = generateId();
      const zIndex = getNextZIndex();

      const alertOptions = typeof message === 'string'
        ? { message, type }
        : message;

      const alertProps = {
        isOpen: true,
        title: alertOptions.title || 'Alert',
        message: alertOptions.message,
        confirmText: alertOptions.buttonText || 'OK',
        cancelText: null, // アラートはキャンセルボタンなし
        variant: alertOptions.type || type,
        onConfirm: () => {
          closeModal(id);
          resolve();
        },
        onCancel: () => {
          closeModal(id);
          resolve();
        }
      };

      const modalInstance = {
        id,
        component: ConfirmDialog,
        props: alertProps,
        zIndex,
        createdAt: Date.now(),
        resolve
      };

      setModals((prevModals) => [...prevModals, modalInstance]);
    });
  }, [generateId, getNextZIndex, closeModal]);

  // カスタムモーダル表示
  const showCustomModal = useCallback((component, props = {}) => {
    const id = generateId();
    const zIndex = getNextZIndex();

    const customProps = {
      ...props,
      isOpen: true,
      onClose: () => closeModal(id)
    };

    const modalInstance = {
      id,
      component,
      props: customProps,
      zIndex,
      createdAt: Date.now()
    };

    setModals((prevModals) => [...prevModals, modalInstance]);
    return id;
  }, [generateId, getNextZIndex, closeModal]);

  // ローディングオーバーレイ表示
  const showLoading = useCallback((message) => {
    const id = generateId();
    const zIndex = getNextZIndex();

    const LoadingOverlay = () => (
      <div style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        zIndex
      }}>
        <LoadingSpinner
          fullscreen={true}
          message={message}
          variant="spinner"
          size="large"
        />
      </div>
    );

    const modalInstance = {
      id,
      component: LoadingOverlay,
      props: {},
      zIndex,
      createdAt: Date.now()
    };

    setModals((prevModals) => [...prevModals, modalInstance]);
    return id;
  }, [generateId, getNextZIndex]);

  // Context値
  const contextValue = {
    modals,
    showModal,
    closeModal,
    closeAllModals,
    showConfirm,
    showAlert,
    showCustomModal,
    showLoading
  };

  return (
    <ModalContext.Provider value={contextValue}>
      {children}

      {/* モーダル群の描画 */}
      {modals.map((modal) => {
        const ModalComponent = modal.component;
        return (
          <ModalComponent
            key={modal.id}
            {...modal.props}
            style={{
              ...modal.props.style,
              zIndex: modal.zIndex
            }}
          />
        );
      })}
    </ModalContext.Provider>
  );
};

/**
 * useModal Hook
 * モーダル機能を利用するためのカスタムフック
 *
 * @returns {Object} モーダル操作用のメソッド群
 * @returns {Function} showModal - モーダル表示
 * @returns {Function} closeModal - モーダル閉じる
 * @returns {Function} closeAllModals - 全モーダル閉じる
 * @returns {Function} showConfirm - 確認ダイアログ表示（Promise返却）
 * @returns {Function} showAlert - アラートダイアログ表示
 * @returns {Function} showCustomModal - カスタムモーダル表示
 * @returns {Function} showLoading - ローディングオーバーレイ表示
 * @returns {Array} modals - 現在のモーダル一覧
 */
const useModal = () => {
  const context = useContext(ModalContext);

  if (!context) {
    throw new Error('useModal must be used within a ModalProvider');
  }

  return context;
};

export { ModalProvider, useModal };
export default ModalProvider;