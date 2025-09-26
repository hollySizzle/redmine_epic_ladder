import React, { forwardRef, useState, useCallback } from 'react';
import './Input.scss';

/**
 * Input Component
 * 統一されたテキスト入力コンポーネント
 *
 * @param {Object} props
 * @param {'text'|'email'|'password'|'number'|'tel'|'url'|'search'} props.type - 入力タイプ
 * @param {string} props.label - ラベル
 * @param {string} props.value - 入力値
 * @param {Function} props.onChange - 変更ハンドラー
 * @param {string} props.placeholder - プレースホルダー
 * @param {string} props.error - エラーメッセージ
 * @param {string} props.helperText - ヘルプテキスト
 * @param {boolean} props.required - 必須かどうか
 * @param {boolean} props.disabled - 無効化状態
 * @param {boolean} props.readOnly - 読み取り専用
 * @param {'small'|'medium'|'large'} props.size - サイズ
 * @param {string} props.leftIcon - 左側アイコンクラス
 * @param {string} props.rightIcon - 右側アイコンクラス
 * @param {React.ReactNode} props.leftAddon - 左側アドオン
 * @param {React.ReactNode} props.rightAddon - 右側アドオン
 * @param {boolean} props.clearable - クリア可能かどうか
 * @param {Function} props.onClear - クリアハンドラー
 * @param {number} props.maxLength - 最大文字数
 * @param {boolean} props.showCounter - 文字カウンター表示
 * @param {string} props.className - 追加CSSクラス
 */
const Input = forwardRef(({
  type = 'text',
  label,
  value = '',
  onChange,
  placeholder,
  error,
  helperText,
  required = false,
  disabled = false,
  readOnly = false,
  size = 'medium',
  leftIcon,
  rightIcon,
  leftAddon,
  rightAddon,
  clearable = false,
  onClear,
  maxLength,
  showCounter = false,
  className = '',
  ...props
}, ref) => {
  const [isFocused, setIsFocused] = useState(false);

  // フォーカス処理
  const handleFocus = useCallback((event) => {
    setIsFocused(true);
    props.onFocus?.(event);
  }, [props.onFocus]);

  const handleBlur = useCallback((event) => {
    setIsFocused(false);
    props.onBlur?.(event);
  }, [props.onBlur]);

  // 変更処理
  const handleChange = useCallback((event) => {
    onChange?.(event.target.value, event);
  }, [onChange]);

  // クリア処理
  const handleClear = useCallback(() => {
    onChange?.('');
    onClear?.();
  }, [onChange, onClear]);

  // ID生成
  const inputId = props.id || `input-${Math.random().toString(36).substr(2, 9)}`;
  const errorId = error ? `${inputId}-error` : undefined;
  const helperTextId = helperText ? `${inputId}-helper` : undefined;

  const hasValue = value && value.length > 0;
  const showClearButton = clearable && hasValue && !disabled && !readOnly;
  const characterCount = typeof value === 'string' ? value.length : 0;

  const containerClassName = [
    'input_container',
    `input_container_${size}`,
    isFocused ? 'input_container_focused' : '',
    error ? 'input_container_error' : '',
    disabled ? 'input_container_disabled' : '',
    hasValue ? 'input_container_has_value' : '',
    className
  ].filter(Boolean).join(' ');

  const inputClassName = [
    'input',
    `input_${size}`,
    leftIcon || leftAddon ? 'input_has_left' : '',
    rightIcon || rightAddon || showClearButton ? 'input_has_right' : ''
  ].filter(Boolean).join(' ');

  return (
    <div className={containerClassName}>
      {/* ラベル */}
      {label && (
        <label htmlFor={inputId} className="input_label">
          {label}
          {required && <span className="input_required">*</span>}
        </label>
      )}

      {/* 入力フィールドコンテナ */}
      <div className="input_field_container">
        {/* 左側アドオン */}
        {leftAddon && (
          <div className="input_addon input_addon_left">
            {leftAddon}
          </div>
        )}

        {/* 左側アイコン */}
        {leftIcon && (
          <div className="input_icon input_icon_left">
            <i className={leftIcon} />
          </div>
        )}

        {/* メイン入力フィールド */}
        <input
          ref={ref}
          id={inputId}
          type={type}
          className={inputClassName}
          value={value}
          onChange={handleChange}
          onFocus={handleFocus}
          onBlur={handleBlur}
          placeholder={placeholder}
          required={required}
          disabled={disabled}
          readOnly={readOnly}
          maxLength={maxLength}
          aria-invalid={error ? 'true' : 'false'}
          aria-describedby={[errorId, helperTextId].filter(Boolean).join(' ') || undefined}
          {...props}
        />

        {/* クリアボタン */}
        {showClearButton && (
          <button
            type="button"
            className="input_clear"
            onClick={handleClear}
            aria-label="Clear input"
          >
            <i className="icon-x" />
          </button>
        )}

        {/* 右側アイコン */}
        {rightIcon && !showClearButton && (
          <div className="input_icon input_icon_right">
            <i className={rightIcon} />
          </div>
        )}

        {/* 右側アドオン */}
        {rightAddon && (
          <div className="input_addon input_addon_right">
            {rightAddon}
          </div>
        )}
      </div>

      {/* フッター（エラー・ヘルプ・カウンター） */}
      <div className="input_footer">
        <div className="input_messages">
          {/* エラーメッセージ */}
          {error && (
            <div id={errorId} className="input_error" role="alert">
              <i className="icon-alert-circle" />
              {error}
            </div>
          )}

          {/* ヘルプテキスト */}
          {helperText && !error && (
            <div id={helperTextId} className="input_helper">
              {helperText}
            </div>
          )}
        </div>

        {/* 文字カウンター */}
        {(showCounter || maxLength) && (
          <div className="input_counter">
            <span className={maxLength && characterCount > maxLength ? 'input_counter_over' : ''}>
              {characterCount}
            </span>
            {maxLength && (
              <span className="input_counter_separator">/{maxLength}</span>
            )}
          </div>
        )}
      </div>
    </div>
  );
});

Input.displayName = 'Input';

export default Input;