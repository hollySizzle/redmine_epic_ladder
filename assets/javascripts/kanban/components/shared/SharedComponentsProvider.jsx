import React from 'react';
import { ToastProvider } from './ToastManager';
import { ModalProvider } from './ModalManager';
import ThemeProvider from './ThemeProvider';

/**
 * Shared Components Provider
 * 全ての共通コンポーネントのProviderを統合するラッパーコンポーネント
 *
 * 使用例:
 * ```jsx
 * import { SharedComponentsProvider } from './components/shared';
 *
 * function App() {
 *   return (
 *     <SharedComponentsProvider>
 *       <YourAppContent />
 *     </SharedComponentsProvider>
 *   );
 * }
 * ```
 *
 * @param {Object} props
 * @param {React.ReactNode} props.children - 子コンポーネント
 * @param {Object} props.toastOptions - Toast設定オプション
 * @param {Object} props.modalOptions - Modal設定オプション
 * @param {Object} props.themeOptions - Theme設定オプション
 */
const SharedComponentsProvider = ({
  children,
  toastOptions = {},
  modalOptions = {},
  themeOptions = {}
}) => {
  // デフォルトのToast設定
  const defaultToastOptions = {
    maxToasts: 5,
    position: 'top-right',
    defaultDuration: {
      success: 3000,
      error: 5000,
      warning: 4000,
      info: 3000
    },
    ...toastOptions
  };

  // デフォルトのModal設定
  const defaultModalOptions = {
    baseZIndex: 1050,
    ...modalOptions
  };

  // デフォルトのTheme設定
  const defaultThemeOptions = {
    defaultMode: 'system',
    enableSystemTheme: true,
    storageKey: 'kanban-theme-mode',
    ...themeOptions
  };

  return (
    <ThemeProvider {...defaultThemeOptions}>
      <ModalProvider {...defaultModalOptions}>
        <ToastProvider {...defaultToastOptions}>
          {children}
        </ToastProvider>
      </ModalProvider>
    </ThemeProvider>
  );
};

/**
 * 便利なカスタムフック：共通コンポーネント機能をまとめて利用
 *
 * 使用例:
 * ```jsx
 * import { useSharedComponents } from './components/shared';
 *
 * function MyComponent() {
 *   const { toast, modal } = useSharedComponents();
 *
 *   const handleSuccess = () => {
 *     toast.showSuccess('操作が完了しました');
 *   };
 *
 *   const handleDelete = async () => {
 *     const confirmed = await modal.showConfirm({
 *       title: '削除確認',
 *       message: 'この項目を削除してもよろしいですか？',
 *       variant: 'danger'
 *     });
 *
 *     if (confirmed) {
 *       // 削除処理...
 *       toast.showSuccess('削除しました');
 *     }
 *   };
 *
 *   return (
 *     <div>
 *       <button onClick={handleSuccess}>成功通知</button>
 *       <button onClick={handleDelete}>削除確認</button>
 *     </div>
 *   );
 * }
 * ```
 */
import { useToast } from './ToastManager';
import { useModal } from './ModalManager';
import { useTheme } from './ThemeProvider';

const useSharedComponents = () => {
  const toast = useToast();
  const modal = useModal();
  const theme = useTheme();

  return {
    toast,
    modal,
    theme,
    // 便利なショートカットメソッド
    notify: {
      success: toast.showSuccess,
      error: toast.showError,
      warning: toast.showWarning,
      info: toast.showInfo
    },
    dialog: {
      confirm: modal.showConfirm,
      alert: modal.showAlert,
      loading: modal.showLoading
    },
    ui: {
      toggleTheme: theme.toggleMode,
      setTheme: theme.setMode,
      currentTheme: theme.mode
    }
  };
};

export { SharedComponentsProvider, useSharedComponents };
export default SharedComponentsProvider;