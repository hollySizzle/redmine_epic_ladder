import React from 'react';
import { useDropTarget } from '../../hooks/useDropTarget';

interface AddButtonProps {
  type: 'epic' | 'version' | 'feature' | 'user-story' | 'task' | 'test' | 'bug';
  label: string;
  onClick?: () => void;
  dataAddButton?: string;
  className?: string;
  epicId?: string;
  versionId?: string;
}

export const AddButton: React.FC<AddButtonProps> = ({
  type,
  label,
  onClick,
  dataAddButton,
  className = '',
  epicId,
  versionId
}) => {
  const baseClass = `add-button add-${type}-btn`;
  const fullClass = className ? `${baseClass} ${className}` : baseClass;

  // Addボタンをドロップターゲットとして登録
  const dropTargetType = type === 'feature' ? 'feature-card' : type;
  const ref = useDropTarget({
    type: dropTargetType,
    id: `add-button-${type}-${epicId || 'none'}-${versionId || 'none'}`,
    data: { isAddButton: true, epicId, versionId },
    canDrop: (sourceData) => sourceData.type === dropTargetType,
  }) as unknown as React.RefObject<HTMLButtonElement>;

  const handleClick = () => {
    if (onClick) {
      onClick();
    } else {
      alert(`${label} clicked!`);
    }
  };

  return (
    <button
      ref={ref}
      className={fullClass}
      data-add-button={dataAddButton}
      onClick={handleClick}
    >
      {label}
    </button>
  );
};
