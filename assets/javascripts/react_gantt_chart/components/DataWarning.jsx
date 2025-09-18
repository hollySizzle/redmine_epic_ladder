import React from 'react';

/**
 * データ制限警告コンポーネント
 * @param {Object} props
 * @param {Object} props.warning - 警告情報
 * @param {Function} props.onClose - 警告を閉じる際のコールバック
 */
const DataWarning = ({ warning, onClose }) => {
  if (!warning || !warning.data_truncated) return null;

  const severity = warning.severity || 'warning';
  const bgColor = severity === 'info' ? 'bg-blue-50' : 'bg-yellow-50';
  const borderColor = severity === 'info' ? 'border-blue-200' : 'border-yellow-200';
  const textColor = severity === 'info' ? 'text-blue-800' : 'text-yellow-800';
  const iconColor = severity === 'info' ? 'text-blue-400' : 'text-yellow-400';

  return (
    <div className={`${bgColor} ${borderColor} ${textColor} border-l-4 p-4 mb-4`}>
      <div className="flex">
        <div className="flex-shrink-0">
          <svg 
            className={`h-5 w-5 ${iconColor}`} 
            xmlns="http://www.w3.org/2000/svg" 
            viewBox="0 0 20 20" 
            fill="currentColor"
          >
            {severity === 'info' ? (
              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
            ) : (
              <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
            )}
          </svg>
        </div>
        <div className="ml-3 flex-1">
          <p className="text-sm">
            <span className="font-medium">
              表示データが制限されています: 
            </span>
            {' '}
            {warning.displayed_count} / {warning.total_count} 件 
            （制限: {warning.limit} 件）
          </p>
          <p className="mt-1 text-sm">
            {warning.message}
          </p>
        </div>
        <div className="ml-auto pl-3">
          <div className="-mx-1.5 -my-1.5">
            <button
              type="button"
              onClick={onClose}
              className={`inline-flex rounded-md p-1.5 ${textColor} hover:${bgColor} focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-${severity === 'info' ? 'blue' : 'yellow'}-50 focus:ring-${severity === 'info' ? 'blue' : 'yellow'}-600`}
            >
              <span className="sr-only">閉じる</span>
              <svg className="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DataWarning;