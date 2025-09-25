# 共通UIコンポーネント設計仕様書

## 🔗 関連ドキュメント
- @vibes/logics/ui_components/feature_card/feature_card_component_specification.md
- @vibes/logics/ui_components/kanban_grid/kanban_grid_layout_specification.md
- @vibes/rules/technical_architecture_standards.md

## 1. 概要

Feature CardとKanban Gridで共通利用するReactコンポーネント群。D&D操作、モーダル表示、通知システム、フォーム要素の統一実装。

## 2. 共通コンポーネント一覧

### 2.1 コンポーネント階層

```
SharedComponents/
├── Layout/
│   ├── Modal
│   ├── Tooltip
│   ├── Popover
│   └── ConfirmDialog
├── Form/
│   ├── Button
│   ├── Input
│   ├── Select
│   ├── Textarea
│   └── DatePicker
├── Display/
│   ├── Badge
│   ├── StatusChip
│   ├── Avatar
│   └── LoadingSpinner
├── Navigation/
│   ├── Tabs
│   ├── Breadcrumb
│   └── Pagination
└── Feedback/
    ├── Toast
    ├── Alert
    └── ProgressBar
```

## 3. Layout コンポーネント

### 3.1 Modal

```javascript
// assets/javascripts/kanban/components/shared/Modal.jsx
import React, { useEffect } from 'react';
import ReactDOM from 'react-dom';

export const Modal = ({
  isOpen,
  onClose,
  title,
  children,
  size = 'medium', // 'small' | 'medium' | 'large' | 'fullscreen'
  closeOnBackdropClick = true,
  closeOnEscape = true,
  className = ''
}) => {
  useEffect(() => {
    if (!isOpen) return;

    const handleEscape = (event) => {
      if (event.key === 'Escape' && closeOnEscape) {
        onClose();
      }
    };

    document.addEventListener('keydown', handleEscape);
    document.body.style.overflow = 'hidden';

    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, closeOnEscape, onClose]);

  if (!isOpen) return null;

  const modalContent = (
    <div className="modal-overlay">
      <div
        className="modal-backdrop"
        onClick={closeOnBackdropClick ? onClose : undefined}
      />
      <div className={`modal-container modal-${size} ${className}`}>
        <div className="modal-header">
          <h2 className="modal-title">{title}</h2>
          <button
            className="modal-close-btn"
            onClick={onClose}
            aria-label="モーダルを閉じる"
          >
            ✕
          </button>
        </div>

        <div className="modal-body">
          {children}
        </div>
      </div>
    </div>
  );

  // ポータルを使用してbody直下にレンダリング
  return ReactDOM.createPortal(modalContent, document.body);
};
```

### 3.2 Tooltip

```javascript
// assets/javascripts/kanban/components/shared/Tooltip.jsx
import React, { useState, useRef, useEffect } from 'react';

export const Tooltip = ({
  content,
  children,
  position = 'top', // 'top' | 'bottom' | 'left' | 'right'
  delay = 300,
  disabled = false
}) => {
  const [isVisible, setIsVisible] = useState(false);
  const [tooltipStyle, setTooltipStyle] = useState({});
  const triggerRef = useRef(null);
  const tooltipRef = useRef(null);
  const timeoutRef = useRef(null);

  const showTooltip = () => {
    if (disabled) return;

    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    timeoutRef.current = setTimeout(() => {
      setIsVisible(true);
      calculatePosition();
    }, delay);
  };

  const hideTooltip = () => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
    setIsVisible(false);
  };

  const calculatePosition = () => {
    if (!triggerRef.current || !tooltipRef.current) return;

    const triggerRect = triggerRef.current.getBoundingClientRect();
    const tooltipRect = tooltipRef.current.getBoundingClientRect();

    let left, top;

    switch (position) {
      case 'top':
        left = triggerRect.left + (triggerRect.width - tooltipRect.width) / 2;
        top = triggerRect.top - tooltipRect.height - 8;
        break;
      case 'bottom':
        left = triggerRect.left + (triggerRect.width - tooltipRect.width) / 2;
        top = triggerRect.bottom + 8;
        break;
      case 'left':
        left = triggerRect.left - tooltipRect.width - 8;
        top = triggerRect.top + (triggerRect.height - tooltipRect.height) / 2;
        break;
      case 'right':
        left = triggerRect.right + 8;
        top = triggerRect.top + (triggerRect.height - tooltipRect.height) / 2;
        break;
      default:
        left = triggerRect.left;
        top = triggerRect.top;
    }

    setTooltipStyle({ left, top });
  };

  useEffect(() => {
    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, []);

  return (
    <div className="tooltip-wrapper">
      <div
        ref={triggerRef}
        onMouseEnter={showTooltip}
        onMouseLeave={hideTooltip}
        onFocus={showTooltip}
        onBlur={hideTooltip}
      >
        {children}
      </div>

      {isVisible && (
        <div
          ref={tooltipRef}
          className={`tooltip tooltip-${position}`}
          style={{
            position: 'fixed',
            ...tooltipStyle,
            zIndex: 9999
          }}
        >
          {content}
        </div>
      )}
    </div>
  );
};
```

### 3.3 ConfirmDialog

```javascript
// assets/javascripts/kanban/components/shared/ConfirmDialog.jsx
import React from 'react';
import { Modal } from './Modal';

export const ConfirmDialog = ({
  isOpen,
  title = '確認',
  message,
  confirmText = '確認',
  cancelText = 'キャンセル',
  onConfirm,
  onCancel,
  confirmButtonType = 'danger' // 'primary' | 'danger' | 'warning'
}) => {
  const handleConfirm = () => {
    onConfirm();
    onCancel(); // ダイアログを閉じる
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onCancel}
      title={title}
      size="small"
      closeOnBackdropClick={false}
    >
      <div className="confirm-dialog">
        <div className="confirm-message">
          {message}
        </div>

        <div className="confirm-actions">
          <button
            className="btn btn-secondary"
            onClick={onCancel}
          >
            {cancelText}
          </button>

          <button
            className={`btn btn-${confirmButtonType}`}
            onClick={handleConfirm}
          >
            {confirmText}
          </button>
        </div>
      </div>
    </Modal>
  );
};
```

## 4. Form コンポーネント

### 4.1 Button

```javascript
// assets/javascripts/kanban/components/shared/Button.jsx
import React from 'react';

export const Button = ({
  children,
  variant = 'primary', // 'primary' | 'secondary' | 'danger' | 'warning' | 'success'
  size = 'medium', // 'small' | 'medium' | 'large'
  disabled = false,
  loading = false,
  onClick,
  type = 'button',
  className = '',
  ...props
}) => {
  const handleClick = (event) => {
    if (disabled || loading) return;
    onClick?.(event);
  };

  return (
    <button
      type={type}
      className={`btn btn-${variant} btn-${size} ${className} ${loading ? 'loading' : ''}`}
      disabled={disabled || loading}
      onClick={handleClick}
      {...props}
    >
      {loading && <span className="btn-spinner" />}
      <span className="btn-text">{children}</span>
    </button>
  );
};
```

### 4.2 Input

```javascript
// assets/javascripts/kanban/components/shared/Input.jsx
import React, { forwardRef } from 'react';

export const Input = forwardRef(({
  label,
  error,
  helper,
  required = false,
  disabled = false,
  placeholder,
  type = 'text',
  size = 'medium', // 'small' | 'medium' | 'large'
  className = '',
  ...props
}, ref) => {
  const inputId = `input-${Math.random().toString(36).substr(2, 9)}`;

  return (
    <div className={`input-group ${className}`}>
      {label && (
        <label
          htmlFor={inputId}
          className={`input-label ${required ? 'required' : ''}`}
        >
          {label}
          {required && <span className="required-mark">*</span>}
        </label>
      )}

      <input
        ref={ref}
        id={inputId}
        type={type}
        placeholder={placeholder}
        disabled={disabled}
        className={`input input-${size} ${error ? 'error' : ''}`}
        {...props}
      />

      {error && (
        <div className="input-error">{error}</div>
      )}

      {helper && !error && (
        <div className="input-helper">{helper}</div>
      )}
    </div>
  );
});

Input.displayName = 'Input';
```

### 4.3 Select

```javascript
// assets/javascripts/kanban/components/shared/Select.jsx
import React, { forwardRef } from 'react';

export const Select = forwardRef(({
  label,
  options = [],
  error,
  helper,
  required = false,
  disabled = false,
  placeholder,
  size = 'medium',
  className = '',
  ...props
}, ref) => {
  const selectId = `select-${Math.random().toString(36).substr(2, 9)}`;

  return (
    <div className={`select-group ${className}`}>
      {label && (
        <label
          htmlFor={selectId}
          className={`select-label ${required ? 'required' : ''}`}
        >
          {label}
          {required && <span className="required-mark">*</span>}
        </label>
      )}

      <select
        ref={ref}
        id={selectId}
        disabled={disabled}
        className={`select select-${size} ${error ? 'error' : ''}`}
        {...props}
      >
        {placeholder && (
          <option value="" disabled>
            {placeholder}
          </option>
        )}

        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>

      {error && (
        <div className="select-error">{error}</div>
      )}

      {helper && !error && (
        <div className="select-helper">{helper}</div>
      )}
    </div>
  );
});

Select.displayName = 'Select';
```

## 5. Display コンポーネント

### 5.1 Badge

```javascript
// assets/javascripts/kanban/components/shared/Badge.jsx
import React from 'react';

export const Badge = ({
  children,
  variant = 'default', // 'default' | 'primary' | 'success' | 'warning' | 'danger'
  size = 'medium', // 'small' | 'medium' | 'large'
  className = ''
}) => {
  return (
    <span className={`badge badge-${variant} badge-${size} ${className}`}>
      {children}
    </span>
  );
};
```

### 5.2 StatusChip

```javascript
// assets/javascripts/kanban/components/shared/StatusChip.jsx
import React from 'react';

export const StatusChip = ({
  status,
  source = 'direct', // 'direct' | 'inherited' | 'none'
  onClick,
  className = ''
}) => {
  const getStatusConfig = (status) => {
    const configs = {
      '新規': { color: '#f8f9fa', textColor: '#6c757d', border: '#dee2e6' },
      '進行中': { color: '#fff3cd', textColor: '#856404', border: '#ffeeba' },
      '完了': { color: '#d4edda', textColor: '#155724', border: '#c3e6cb' },
      '未着手': { color: '#f5f5f5', textColor: '#6c757d', border: '#dee2e6' },
      '対応中': { color: '#cce5ff', textColor: '#004085', border: '#99d1ff' },
      '要確認': { color: '#ffeaa7', textColor: '#6c5500', border: '#fdd835' }
    };

    return configs[status] || configs['未着手'];
  };

  const getSourceStyle = () => {
    const styles = {
      direct: { borderStyle: 'solid', opacity: 1.0 },
      inherited: { borderStyle: 'dashed', opacity: 0.8 },
      none: { borderStyle: 'dotted', opacity: 0.6 }
    };

    return styles[source];
  };

  const statusConfig = getStatusConfig(status);
  const sourceStyle = getSourceStyle();

  const chipStyle = {
    backgroundColor: statusConfig.color,
    color: statusConfig.textColor,
    border: `1px ${sourceStyle.borderStyle} ${statusConfig.border}`,
    opacity: sourceStyle.opacity
  };

  const getTooltipText = () => {
    const tooltips = {
      direct: '直接設定されたステータス',
      inherited: '親から継承されたステータス',
      none: 'ステータス未設定'
    };
    return tooltips[source];
  };

  return (
    <span
      className={`status-chip status-${source} ${onClick ? 'clickable' : ''} ${className}`}
      style={chipStyle}
      onClick={onClick}
      title={getTooltipText()}
    >
      {status}
    </span>
  );
};
```

### 5.3 Avatar

```javascript
// assets/javascripts/kanban/components/shared/Avatar.jsx
import React from 'react';

export const Avatar = ({
  user,
  size = 'medium', // 'small' | 'medium' | 'large'
  showName = false,
  showTooltip = true,
  onClick,
  className = ''
}) => {
  const getInitials = (user) => {
    if (!user || !user.name) return '?';

    const names = user.name.split(' ');
    if (names.length >= 2) {
      return `${names[0][0]}${names[names.length - 1][0]}`;
    }
    return names[0][0] || '?';
  };

  const getAvatarUrl = (user) => {
    // Redmineのアバターシステムと連携
    if (user?.avatar_url) {
      return user.avatar_url;
    }
    // Gravatarフォールバック
    if (user?.email) {
      const md5 = require('crypto').createHash('md5').update(user.email.toLowerCase()).digest('hex');
      return `https://www.gravatar.com/avatar/${md5}?s=40&d=identicon`;
    }
    return null;
  };

  const avatarUrl = getAvatarUrl(user);
  const initials = getInitials(user);
  const displayName = user?.name || '未割当';

  return (
    <div
      className={`avatar avatar-${size} ${onClick ? 'clickable' : ''} ${className}`}
      onClick={onClick}
      title={showTooltip ? displayName : undefined}
    >
      {avatarUrl ? (
        <img
          src={avatarUrl}
          alt={displayName}
          className="avatar-image"
        />
      ) : (
        <div className="avatar-initials">
          {initials}
        </div>
      )}

      {showName && (
        <span className="avatar-name">{displayName}</span>
      )}
    </div>
  );
};
```

## 6. Feedback コンポーネント

### 6.1 Toast

```javascript
// assets/javascripts/kanban/components/shared/Toast.jsx
import React, { useEffect, useState } from 'react';
import ReactDOM from 'react-dom';

export const Toast = ({
  message,
  type = 'info', // 'info' | 'success' | 'warning' | 'error'
  duration = 5000,
  position = 'top-right', // 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left'
  onClose
}) => {
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => {
      setIsVisible(false);
      setTimeout(() => {
        onClose?.();
      }, 300); // フェードアウトアニメーション時間
    }, duration);

    return () => clearTimeout(timer);
  }, [duration, onClose]);

  const getIcon = () => {
    const icons = {
      info: 'ℹ️',
      success: '✅',
      warning: '⚠️',
      error: '❌'
    };
    return icons[type];
  };

  const toastContent = (
    <div className={`toast toast-${type} toast-${position} ${isVisible ? 'visible' : 'hidden'}`}>
      <div className="toast-content">
        <span className="toast-icon">{getIcon()}</span>
        <span className="toast-message">{message}</span>
        <button
          className="toast-close"
          onClick={() => {
            setIsVisible(false);
            setTimeout(() => onClose?.(), 300);
          }}
        >
          ✕
        </button>
      </div>
    </div>
  );

  return ReactDOM.createPortal(toastContent, document.body);
};

// Toast管理用Hook
export const useToast = () => {
  const [toasts, setToasts] = useState([]);

  const showToast = (message, type = 'info', options = {}) => {
    const id = Math.random().toString(36).substr(2, 9);
    const toast = {
      id,
      message,
      type,
      ...options
    };

    setToasts(prev => [...prev, toast]);

    return id;
  };

  const hideToast = (id) => {
    setToasts(prev => prev.filter(toast => toast.id !== id));
  };

  const ToastContainer = () => (
    <>
      {toasts.map(toast => (
        <Toast
          key={toast.id}
          message={toast.message}
          type={toast.type}
          duration={toast.duration}
          position={toast.position}
          onClose={() => hideToast(toast.id)}
        />
      ))}
    </>
  );

  return {
    showToast,
    hideToast,
    ToastContainer
  };
};
```

### 6.2 LoadingSpinner

```javascript
// assets/javascripts/kanban/components/shared/LoadingSpinner.jsx
import React from 'react';

export const LoadingSpinner = ({
  size = 'medium', // 'small' | 'medium' | 'large'
  color = 'primary',
  overlay = false,
  message = '読み込み中...'
}) => {
  const spinner = (
    <div className={`spinner spinner-${size} spinner-${color}`}>
      <div className="spinner-circle"></div>
      {message && (
        <div className="spinner-message">{message}</div>
      )}
    </div>
  );

  if (overlay) {
    return (
      <div className="spinner-overlay">
        {spinner}
      </div>
    );
  }

  return spinner;
};
```

## 7. CSS共通スタイル

### 7.1 レイアウトコンポーネント

```scss
// assets/stylesheets/kanban/shared/layout.scss
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 1000;
}

.modal-backdrop {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
}

.modal-container {
  position: relative;
  background: white;
  border-radius: 8px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
  margin: 50px auto;
  max-height: calc(100vh - 100px);
  overflow: hidden;
  display: flex;
  flex-direction: column;

  &.modal-small { width: 400px; }
  &.modal-medium { width: 600px; }
  &.modal-large { width: 800px; }
  &.modal-fullscreen {
    width: calc(100vw - 40px);
    height: calc(100vh - 40px);
    margin: 20px;
  }

  .modal-header {
    padding: 16px 20px;
    border-bottom: 1px solid #e9ecef;
    display: flex;
    justify-content: space-between;
    align-items: center;

    .modal-title {
      margin: 0;
      font-size: 18px;
      font-weight: 600;
    }

    .modal-close-btn {
      background: none;
      border: none;
      font-size: 18px;
      cursor: pointer;
      padding: 4px;

      &:hover {
        background: #f8f9fa;
        border-radius: 4px;
      }
    }
  }

  .modal-body {
    padding: 20px;
    overflow-y: auto;
    flex: 1;
  }
}

.tooltip {
  background: rgba(0, 0, 0, 0.9);
  color: white;
  padding: 6px 8px;
  border-radius: 4px;
  font-size: 12px;
  white-space: nowrap;
  max-width: 200px;
  text-align: center;

  &.tooltip-top::after {
    content: '';
    position: absolute;
    top: 100%;
    left: 50%;
    margin-left: -5px;
    border: 5px solid transparent;
    border-top-color: rgba(0, 0, 0, 0.9);
  }

  // その他の方向のarrowスタイル...
}
```

### 7.2 フォームコンポーネント

```scss
// assets/stylesheets/kanban/shared/form.scss
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  text-decoration: none;

  &:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  &.loading {
    pointer-events: none;

    .btn-spinner {
      width: 16px;
      height: 16px;
      border: 2px solid transparent;
      border-top: 2px solid currentColor;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin-right: 8px;
    }
  }

  // サイズバリエーション
  &.btn-small {
    padding: 4px 8px;
    font-size: 12px;
  }

  &.btn-large {
    padding: 12px 24px;
    font-size: 16px;
  }

  // カラーバリエーション
  &.btn-primary {
    background: #007bff;
    color: white;

    &:hover { background: #0056b3; }
  }

  &.btn-secondary {
    background: #6c757d;
    color: white;

    &:hover { background: #545b62; }
  }

  &.btn-danger {
    background: #dc3545;
    color: white;

    &:hover { background: #c82333; }
  }

  &.btn-success {
    background: #28a745;
    color: white;

    &:hover { background: #1e7e34; }
  }

  &.btn-warning {
    background: #ffc107;
    color: #212529;

    &:hover { background: #e0a800; }
  }
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.input-group, .select-group {
  margin-bottom: 16px;

  .input-label, .select-label {
    display: block;
    margin-bottom: 4px;
    font-weight: 500;
    font-size: 14px;

    &.required {
      .required-mark {
        color: #dc3545;
        margin-left: 2px;
      }
    }
  }

  .input, .select {
    width: 100%;
    padding: 8px 12px;
    border: 1px solid #ced4da;
    border-radius: 4px;
    font-size: 14px;
    transition: border-color 0.2s;

    &:focus {
      outline: none;
      border-color: #007bff;
      box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
    }

    &.error {
      border-color: #dc3545;

      &:focus {
        border-color: #dc3545;
        box-shadow: 0 0 0 2px rgba(220, 53, 69, 0.25);
      }
    }

    &:disabled {
      background: #f8f9fa;
      opacity: 0.6;
    }
  }

  .input-error, .select-error {
    color: #dc3545;
    font-size: 12px;
    margin-top: 4px;
  }

  .input-helper, .select-helper {
    color: #6c757d;
    font-size: 12px;
    margin-top: 4px;
  }
}
```

### 7.3 Displayコンポーネント

```scss
// assets/stylesheets/kanban/shared/display.scss
.badge {
  display: inline-block;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;

  &.badge-small {
    padding: 2px 6px;
    font-size: 10px;
  }

  &.badge-large {
    padding: 6px 12px;
    font-size: 12px;
  }

  &.badge-default {
    background: #f8f9fa;
    color: #6c757d;
  }

  &.badge-primary {
    background: #007bff;
    color: white;
  }

  &.badge-success {
    background: #28a745;
    color: white;
  }

  &.badge-warning {
    background: #ffc107;
    color: #212529;
  }

  &.badge-danger {
    background: #dc3545;
    color: white;
  }
}

.status-chip {
  display: inline-block;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 11px;
  font-weight: 500;
  white-space: nowrap;

  &.clickable {
    cursor: pointer;
    transition: opacity 0.2s;

    &:hover {
      opacity: 0.8;
    }
  }
}

.avatar {
  display: inline-flex;
  align-items: center;
  gap: 6px;

  &.clickable {
    cursor: pointer;
  }

  .avatar-image, .avatar-initials {
    width: 24px;
    height: 24px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .avatar-image {
    object-fit: cover;
  }

  .avatar-initials {
    background: #6c757d;
    color: white;
    font-size: 10px;
    font-weight: 600;
  }

  &.avatar-small {
    .avatar-image, .avatar-initials {
      width: 20px;
      height: 20px;
      font-size: 9px;
    }
  }

  &.avatar-large {
    .avatar-image, .avatar-initials {
      width: 32px;
      height: 32px;
      font-size: 12px;
    }
  }

  .avatar-name {
    font-size: 12px;
    color: #495057;
  }
}
```

## 8. React Hook 統合

### 8.1 useModal Hook

```javascript
// assets/javascripts/kanban/hooks/useModal.js
import { useState } from 'react';

export const useModal = (initialOpen = false) => {
  const [isOpen, setIsOpen] = useState(initialOpen);

  const openModal = () => setIsOpen(true);
  const closeModal = () => setIsOpen(false);
  const toggleModal = () => setIsOpen(prev => !prev);

  return {
    isOpen,
    openModal,
    closeModal,
    toggleModal
  };
};
```

### 8.2 useConfirm Hook

```javascript
// assets/javascripts/kanban/hooks/useConfirm.js
import { useState } from 'react';

export const useConfirm = () => {
  const [confirmState, setConfirmState] = useState({
    isOpen: false,
    title: '',
    message: '',
    onConfirm: () => {},
    confirmText: '確認',
    cancelText: 'キャンセル',
    confirmButtonType: 'primary'
  });

  const showConfirm = ({
    title = '確認',
    message,
    onConfirm,
    confirmText = '確認',
    cancelText = 'キャンセル',
    confirmButtonType = 'primary'
  }) => {
    return new Promise((resolve) => {
      setConfirmState({
        isOpen: true,
        title,
        message,
        onConfirm: () => {
          resolve(true);
          onConfirm?.();
        },
        confirmText,
        cancelText,
        confirmButtonType
      });
    });
  };

  const hideConfirm = () => {
    setConfirmState(prev => ({ ...prev, isOpen: false }));
  };

  return {
    confirmState,
    showConfirm,
    hideConfirm
  };
};
```

---

*Feature CardとKanban Grid共通のReactコンポーネント群。統一されたUI/UXとRedmine統合を実現*