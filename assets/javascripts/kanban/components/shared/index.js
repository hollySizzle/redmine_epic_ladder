/**
 * Shared Components Export File
 * 共通UIコンポーネントの統一エクスポートファイル
 *
 * このファイルは設計書に基づいて実装されたshared componentsを
 * 一箇所から利用可能にするためのインデックスファイルです。
 */

// Basic Components
export { default as Button } from './Button';
export { default as Modal } from './Modal';
export { default as Tooltip } from './Tooltip';

// High Priority Components
export { default as Toast } from './Toast';
export { default as StatusChip } from './StatusChip';
export { default as ConfirmDialog } from './ConfirmDialog';
export { default as LoadingSpinner } from './LoadingSpinner';

// Form Components
export { default as Alert } from './Alert';
export { default as Badge } from './Badge';
export { default as Avatar } from './Avatar';
export { default as Input } from './Input';
export { default as Select } from './Select';

// Navigation Components
export { default as Tabs } from './Tabs';
export { default as Breadcrumb } from './Breadcrumb';
export { default as Pagination } from './Pagination';

// Data Display Components
export { default as ProgressBar } from './ProgressBar';

// Theme System
export { default as ThemeProvider, useTheme, useThemeValue, useBreakpoint } from './ThemeProvider';

// Context Managers
export { ToastProvider, useToast } from './ToastManager';
export { ModalProvider, useModal } from './ModalManager';
export { SharedComponentsProvider, useSharedComponents } from './SharedComponentsProvider';

// Re-export everything for comprehensive access
export * from './Button';
export * from './Modal';
export * from './Tooltip';
export * from './Toast';
export * from './StatusChip';
export * from './ConfirmDialog';
export * from './LoadingSpinner';
export * from './Alert';
export * from './Badge';
export * from './Avatar';
export * from './Input';
export * from './Select';
export * from './Tabs';
export * from './Breadcrumb';
export * from './Pagination';
export * from './ProgressBar';
export * from './ThemeProvider';
export * from './ToastManager';
export * from './ModalManager';
export * from './SharedComponentsProvider';