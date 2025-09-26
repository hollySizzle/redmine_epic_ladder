import React, { useMemo, useCallback } from 'react';
import Button from './Button';
import Select from './Select';
import './Pagination.scss';

/**
 * Pagination Component
 * ページネーションコンポーネント
 *
 * @param {Object} props
 * @param {number} props.currentPage - 現在のページ番号（1ベース）
 * @param {number} props.totalPages - 総ページ数
 * @param {number} props.totalItems - 総アイテム数
 * @param {number} props.itemsPerPage - 1ページあたりのアイテム数
 * @param {Function} props.onPageChange - ページ変更ハンドラー
 * @param {Function} props.onItemsPerPageChange - 1ページあたりのアイテム数変更ハンドラー
 * @param {Array} props.pageSizeOptions - ページサイズ選択肢
 * @param {'simple'|'full'|'compact'} props.variant - 表示バリアント
 * @param {'small'|'medium'|'large'} props.size - サイズ
 * @param {number} props.siblingCount - 現在ページ前後に表示するページ数
 * @param {boolean} props.showFirstLast - 最初/最後ページボタン表示
 * @param {boolean} props.showPrevNext - 前/次ページボタン表示
 * @param {boolean} props.showPageSizeSelector - ページサイズ選択器表示
 * @param {boolean} props.showPageInfo - ページ情報表示
 * @param {boolean} props.disabled - 無効化状態
 * @param {string} props.className - 追加CSSクラス
 */
const Pagination = ({
  currentPage = 1,
  totalPages = 1,
  totalItems = 0,
  itemsPerPage = 10,
  onPageChange,
  onItemsPerPageChange,
  pageSizeOptions = [10, 20, 50, 100],
  variant = 'full',
  size = 'medium',
  siblingCount = 1,
  showFirstLast = true,
  showPrevNext = true,
  showPageSizeSelector = true,
  showPageInfo = true,
  disabled = false,
  className = '',
  ...props
}) => {
  // ページ範囲の計算
  const pageRange = useMemo(() => {
    const totalNumbers = siblingCount * 2 + 5; // 現在 + 前後siblings + first/last + ellipsis
    const totalBlocks = totalNumbers + 2;

    if (totalPages <= totalBlocks) {
      return Array.from({ length: totalPages }, (_, i) => i + 1);
    }

    const leftSiblingIndex = Math.max(currentPage - siblingCount, 1);
    const rightSiblingIndex = Math.min(currentPage + siblingCount, totalPages);

    const shouldShowLeftDots = leftSiblingIndex > 2;
    const shouldShowRightDots = rightSiblingIndex < totalPages - 2;

    if (!shouldShowLeftDots && shouldShowRightDots) {
      const leftItemCount = 3 + 2 * siblingCount;
      const leftRange = Array.from({ length: leftItemCount }, (_, i) => i + 1);
      return [...leftRange, '...', totalPages];
    }

    if (shouldShowLeftDots && !shouldShowRightDots) {
      const rightItemCount = 3 + 2 * siblingCount;
      const rightRange = Array.from(
        { length: rightItemCount },
        (_, i) => totalPages - rightItemCount + i + 1
      );
      return [1, '...', ...rightRange];
    }

    if (shouldShowLeftDots && shouldShowRightDots) {
      const middleRange = Array.from(
        { length: rightSiblingIndex - leftSiblingIndex + 1 },
        (_, i) => leftSiblingIndex + i
      );
      return [1, '...', ...middleRange, '...', totalPages];
    }

    return [];
  }, [currentPage, totalPages, siblingCount]);

  // ページ変更処理
  const handlePageChange = useCallback((page) => {
    if (page < 1 || page > totalPages || page === currentPage || disabled) {
      return;
    }
    onPageChange?.(page);
  }, [currentPage, totalPages, disabled, onPageChange]);

  // ページサイズ変更処理
  const handlePageSizeChange = useCallback((newPageSize) => {
    onItemsPerPageChange?.(newPageSize);
  }, [onItemsPerPageChange]);

  // ページ情報の生成
  const getPageInfo = () => {
    const startItem = (currentPage - 1) * itemsPerPage + 1;
    const endItem = Math.min(currentPage * itemsPerPage, totalItems);
    return `${startItem}-${endItem} of ${totalItems}`;
  };

  // 簡易バリアント
  if (variant === 'simple') {
    return (
      <div className={`pagination pagination_${variant} pagination_${size} ${className}`} {...props}>
        <Button
          variant="ghost"
          size={size}
          disabled={disabled || currentPage <= 1}
          onClick={() => handlePageChange(currentPage - 1)}
          icon="icon-chevron-left"
        >
          Previous
        </Button>

        <span className="pagination_info">
          Page {currentPage} of {totalPages}
        </span>

        <Button
          variant="ghost"
          size={size}
          disabled={disabled || currentPage >= totalPages}
          onClick={() => handlePageChange(currentPage + 1)}
          icon="icon-chevron-right"
        >
          Next
        </Button>
      </div>
    );
  }

  // コンパクトバリアント
  if (variant === 'compact') {
    return (
      <div className={`pagination pagination_${variant} pagination_${size} ${className}`} {...props}>
        <Button
          variant="ghost"
          size={size}
          disabled={disabled || currentPage <= 1}
          onClick={() => handlePageChange(currentPage - 1)}
          icon="icon-chevron-left"
          aria-label="Previous page"
        />

        <div className="pagination_pages_compact">
          {pageRange.map((page, index) => (
            <React.Fragment key={index}>
              {page === '...' ? (
                <span className="pagination_ellipsis">…</span>
              ) : (
                <Button
                  variant={page === currentPage ? 'primary' : 'ghost'}
                  size={size}
                  disabled={disabled}
                  onClick={() => handlePageChange(page)}
                  aria-label={`Page ${page}`}
                  aria-current={page === currentPage ? 'page' : undefined}
                >
                  {page}
                </Button>
              )}
            </React.Fragment>
          ))}
        </div>

        <Button
          variant="ghost"
          size={size}
          disabled={disabled || currentPage >= totalPages}
          onClick={() => handlePageChange(currentPage + 1)}
          icon="icon-chevron-right"
          aria-label="Next page"
        />
      </div>
    );
  }

  // フルバリアント（デフォルト）
  const paginationClassName = [
    'pagination',
    `pagination_${variant}`,
    `pagination_${size}`,
    className
  ].filter(Boolean).join(' ');

  return (
    <div className={paginationClassName} {...props}>
      {/* ページ情報 */}
      {showPageInfo && (
        <div className="pagination_info">
          Showing {getPageInfo()} items
        </div>
      )}

      {/* ページネーション本体 */}
      <div className="pagination_controls">
        {/* 最初のページ */}
        {showFirstLast && (
          <Button
            variant="ghost"
            size={size}
            disabled={disabled || currentPage <= 1}
            onClick={() => handlePageChange(1)}
            icon="icon-chevrons-left"
            aria-label="First page"
          />
        )}

        {/* 前のページ */}
        {showPrevNext && (
          <Button
            variant="ghost"
            size={size}
            disabled={disabled || currentPage <= 1}
            onClick={() => handlePageChange(currentPage - 1)}
            icon="icon-chevron-left"
            aria-label="Previous page"
          />
        )}

        {/* ページ番号 */}
        <div className="pagination_pages">
          {pageRange.map((page, index) => (
            <React.Fragment key={index}>
              {page === '...' ? (
                <span className="pagination_ellipsis">…</span>
              ) : (
                <Button
                  variant={page === currentPage ? 'primary' : 'ghost'}
                  size={size}
                  disabled={disabled}
                  onClick={() => handlePageChange(page)}
                  aria-label={`Page ${page}`}
                  aria-current={page === currentPage ? 'page' : undefined}
                  className="pagination_page"
                >
                  {page}
                </Button>
              )}
            </React.Fragment>
          ))}
        </div>

        {/* 次のページ */}
        {showPrevNext && (
          <Button
            variant="ghost"
            size={size}
            disabled={disabled || currentPage >= totalPages}
            onClick={() => handlePageChange(currentPage + 1)}
            icon="icon-chevron-right"
            aria-label="Next page"
          />
        )}

        {/* 最後のページ */}
        {showFirstLast && (
          <Button
            variant="ghost"
            size={size}
            disabled={disabled || currentPage >= totalPages}
            onClick={() => handlePageChange(totalPages)}
            icon="icon-chevrons-right"
            aria-label="Last page"
          />
        )}
      </div>

      {/* ページサイズ選択器 */}
      {showPageSizeSelector && onItemsPerPageChange && (
        <div className="pagination_page_size">
          <Select
            value={itemsPerPage}
            onChange={handlePageSizeChange}
            options={pageSizeOptions.map(size => ({
              value: size,
              label: `${size} per page`
            }))}
            size={size}
            disabled={disabled}
            className="pagination_page_size_select"
          />
        </div>
      )}
    </div>
  );
};

export default Pagination;