import React from 'react';

interface StatusIndicatorProps {
  status: 'open' | 'closed';
}

export const StatusIndicator: React.FC<StatusIndicatorProps> = ({ status }) => {
  return (
    <span className={`status-indicator status-${status}`}></span>
  );
};
