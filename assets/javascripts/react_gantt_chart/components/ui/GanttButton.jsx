import React from 'react';
import { Button } from 'flowbite-react';

// ボタンバリアント定義（Redmineテーマ適用）
const variants = {
  primary: 'text-redmine-primary-600 bg-redmine-primary-50 hover:bg-redmine-primary-100 border-redmine-primary-200 focus:ring-redmine-primary-500',
  success: 'text-redmine-success-600 bg-redmine-success-50 hover:bg-redmine-success-100 border-redmine-success-200 focus:ring-redmine-success-500',
  warning: 'text-redmine-warning-600 bg-redmine-warning-50 hover:bg-redmine-warning-100 border-redmine-warning-200 focus:ring-redmine-warning-500',
  danger: 'text-redmine-danger-600 bg-redmine-danger-50 hover:bg-redmine-danger-100 border-redmine-danger-200 focus:ring-redmine-danger-500',
  action: 'backdrop-blur-sm bg-redmine-primary-500/10 border-redmine-primary-300/20 text-redmine-primary-700 hover:bg-redmine-primary-500/20 focus:ring-redmine-primary-500/50',
  secondary: 'text-redmine-primary-400 bg-redmine-primary-50 hover:bg-redmine-primary-100 border-redmine-primary-200 focus:ring-redmine-primary-500'
};

/**
 * Gantt チャート用のカスタムボタンコンポーネント
 * Flowbite-React の Button をベースに独自スタイルを適用
 */
const GanttButton = ({ 
  variant = 'primary', 
  size = 'sm', 
  children, 
  className = '',
  ...props 
}) => {
  const variantClasses = variants[variant] || variants.primary;
  
  return (
    <Button
      size={size}
      className={`${variantClasses} transition-all duration-300 rounded-redmine shadow-redmine hover:shadow-redmine-lg font-redmine ${className}`}
      {...props}
    >
      {children}
    </Button>
  );
};

export default GanttButton;