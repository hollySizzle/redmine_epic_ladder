import React, { forwardRef, useState, useCallback, useRef, useEffect } from 'react';
import './Select.scss';

/**
 * Select Component
 * 統一されたセレクトボックスコンポーネント
 *
 * @param {Object} props
 * @param {string} props.label - ラベル
 * @param {string|Array} props.value - 選択値（複数選択の場合は配列）
 * @param {Function} props.onChange - 変更ハンドラー
 * @param {Array} props.options - 選択肢配列
 * @param {string} props.placeholder - プレースホルダー
 * @param {string} props.error - エラーメッセージ
 * @param {string} props.helperText - ヘルプテキスト
 * @param {boolean} props.required - 必須かどうか
 * @param {boolean} props.disabled - 無効化状態
 * @param {boolean} props.multiple - 複数選択可能かどうか
 * @param {boolean} props.searchable - 検索可能かどうか
 * @param {boolean} props.clearable - クリア可能かどうか
 * @param {'small'|'medium'|'large'} props.size - サイズ
 * @param {number} props.maxHeight - ドロップダウンの最大高さ
 * @param {string} props.noOptionsText - 選択肢がない時のテキスト
 * @param {string} props.className - 追加CSSクラス
 */
const Select = forwardRef(({
  label,
  value = multiple ? [] : '',
  onChange,
  options = [],
  placeholder = 'Select...',
  error,
  helperText,
  required = false,
  disabled = false,
  multiple = false,
  searchable = false,
  clearable = false,
  size = 'medium',
  maxHeight = 200,
  noOptionsText = 'No options available',
  className = '',
  ...props
}, ref) => {
  const [isOpen, setIsOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [focusedIndex, setFocusedIndex] = useState(-1);
  const containerRef = useRef(null);
  const searchInputRef = useRef(null);

  // オプションの正規化
  const normalizedOptions = options.map((option, index) => {
    if (typeof option === 'string') {
      return { label: option, value: option, id: index };
    }
    return { ...option, id: option.id || index };
  });

  // フィルタリングされたオプション
  const filteredOptions = searchable && searchQuery
    ? normalizedOptions.filter(option =>
        option.label.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : normalizedOptions;

  // 選択された値の取得
  const selectedOptions = multiple
    ? normalizedOptions.filter(option => value.includes(option.value))
    : normalizedOptions.find(option => option.value === value);

  // 表示テキストの生成
  const getDisplayText = () => {
    if (multiple) {
      if (selectedOptions.length === 0) return placeholder;
      if (selectedOptions.length === 1) return selectedOptions[0].label;
      return `${selectedOptions.length} items selected`;
    }
    return selectedOptions ? selectedOptions.label : placeholder;
  };

  // ドロップダウン開閉
  const handleToggle = useCallback(() => {
    if (disabled) return;
    setIsOpen(!isOpen);
    setSearchQuery('');
    setFocusedIndex(-1);
  }, [isOpen, disabled]);

  // 選択処理
  const handleSelect = useCallback((selectedOption) => {
    if (multiple) {
      const isSelected = value.includes(selectedOption.value);
      const newValue = isSelected
        ? value.filter(v => v !== selectedOption.value)
        : [...value, selectedOption.value];
      onChange?.(newValue);
    } else {
      onChange?.(selectedOption.value);
      setIsOpen(false);
    }
  }, [multiple, value, onChange]);

  // クリア処理
  const handleClear = useCallback((event) => {
    event.stopPropagation();
    onChange?.(multiple ? [] : '');
  }, [multiple, onChange]);

  // 検索処理
  const handleSearchChange = useCallback((event) => {
    setSearchQuery(event.target.value);
    setFocusedIndex(0);
  }, []);

  // キーボード処理
  const handleKeyDown = useCallback((event) => {
    if (!isOpen) {
      if (event.key === 'Enter' || event.key === ' ' || event.key === 'ArrowDown') {
        event.preventDefault();
        setIsOpen(true);
      }
      return;
    }

    switch (event.key) {
      case 'Escape':
        setIsOpen(false);
        break;

      case 'ArrowDown':
        event.preventDefault();
        setFocusedIndex(prev =>
          prev < filteredOptions.length - 1 ? prev + 1 : 0
        );
        break;

      case 'ArrowUp':
        event.preventDefault();
        setFocusedIndex(prev =>
          prev > 0 ? prev - 1 : filteredOptions.length - 1
        );
        break;

      case 'Enter':
        event.preventDefault();
        if (focusedIndex >= 0 && focusedIndex < filteredOptions.length) {
          handleSelect(filteredOptions[focusedIndex]);
        }
        break;

      default:
        break;
    }
  }, [isOpen, focusedIndex, filteredOptions, handleSelect]);

  // 外部クリック処理
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (containerRef.current && !containerRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    };

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  // 検索フィールドのフォーカス
  useEffect(() => {
    if (isOpen && searchable && searchInputRef.current) {
      searchInputRef.current.focus();
    }
  }, [isOpen, searchable]);

  // ID生成
  const selectId = props.id || `select-${Math.random().toString(36).substr(2, 9)}`;
  const errorId = error ? `${selectId}-error` : undefined;
  const helperTextId = helperText ? `${selectId}-helper` : undefined;

  const hasValue = multiple ? selectedOptions.length > 0 : Boolean(selectedOptions);
  const showClearButton = clearable && hasValue && !disabled;

  const containerClassName = [
    'select_container',
    `select_container_${size}`,
    isOpen ? 'select_container_open' : '',
    error ? 'select_container_error' : '',
    disabled ? 'select_container_disabled' : '',
    hasValue ? 'select_container_has_value' : '',
    className
  ].filter(Boolean).join(' ');

  return (
    <div ref={containerRef} className={containerClassName}>
      {/* ラベル */}
      {label && (
        <label htmlFor={selectId} className="select_label">
          {label}
          {required && <span className="select_required">*</span>}
        </label>
      )}

      {/* セレクトフィールド */}
      <div
        className="select_field"
        onClick={handleToggle}
        onKeyDown={handleKeyDown}
        tabIndex={disabled ? -1 : 0}
        role="combobox"
        aria-expanded={isOpen}
        aria-haspopup="listbox"
        aria-invalid={error ? 'true' : 'false'}
        aria-describedby={[errorId, helperTextId].filter(Boolean).join(' ') || undefined}
        {...props}
      >
        {/* 表示テキスト */}
        <div className="select_display">
          <span className={hasValue ? 'select_value' : 'select_placeholder'}>
            {getDisplayText()}
          </span>
        </div>

        {/* クリアボタン */}
        {showClearButton && (
          <button
            type="button"
            className="select_clear"
            onClick={handleClear}
            tabIndex={-1}
            aria-label="Clear selection"
          >
            <i className="icon-x" />
          </button>
        )}

        {/* ドロップダウンアイコン */}
        <div className="select_arrow">
          <i className={`icon-chevron-${isOpen ? 'up' : 'down'}`} />
        </div>
      </div>

      {/* ドロップダウンメニュー */}
      {isOpen && (
        <div
          className="select_dropdown"
          style={{ maxHeight: `${maxHeight}px` }}
        >
          {/* 検索フィールド */}
          {searchable && (
            <div className="select_search">
              <input
                ref={searchInputRef}
                type="text"
                className="select_search_input"
                placeholder="Search options..."
                value={searchQuery}
                onChange={handleSearchChange}
                onClick={(e) => e.stopPropagation()}
              />
            </div>
          )}

          {/* オプションリスト */}
          <ul
            className="select_options"
            role="listbox"
            aria-multiselectable={multiple}
          >
            {filteredOptions.length > 0 ? (
              filteredOptions.map((option, index) => {
                const isSelected = multiple
                  ? value.includes(option.value)
                  : value === option.value;
                const isFocused = index === focusedIndex;

                return (
                  <li
                    key={option.id}
                    className={[
                      'select_option',
                      isSelected ? 'select_option_selected' : '',
                      isFocused ? 'select_option_focused' : '',
                      option.disabled ? 'select_option_disabled' : ''
                    ].filter(Boolean).join(' ')}
                    onClick={() => !option.disabled && handleSelect(option)}
                    role="option"
                    aria-selected={isSelected}
                  >
                    {multiple && (
                      <div className="select_checkbox">
                        <i className={isSelected ? 'icon-check-square' : 'icon-square'} />
                      </div>
                    )}
                    <span className="select_option_text">{option.label}</span>
                  </li>
                );
              })
            ) : (
              <li className="select_no_options">
                {noOptionsText}
              </li>
            )}
          </ul>
        </div>
      )}

      {/* フッター（エラー・ヘルプ） */}
      <div className="select_footer">
        {/* エラーメッセージ */}
        {error && (
          <div id={errorId} className="select_error" role="alert">
            <i className="icon-alert-circle" />
            {error}
          </div>
        )}

        {/* ヘルプテキスト */}
        {helperText && !error && (
          <div id={helperTextId} className="select_helper">
            {helperText}
          </div>
        )}
      </div>
    </div>
  );
});

Select.displayName = 'Select';

export default Select;