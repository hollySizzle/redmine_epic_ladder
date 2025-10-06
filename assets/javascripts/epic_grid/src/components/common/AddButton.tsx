import React, { useRef, useEffect } from 'react';
import { dropTargetForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';

interface AddButtonProps {
  type: 'epic' | 'version' | 'feature' | 'user-story' | 'task' | 'test' | 'bug';
  label: string;
  onClick?: () => void;
  dataAddButton?: string;
  className?: string;
  epicId?: string;
  versionId?: string;
  featureId?: string;
  onDrop?: (sourceData: Record<string, any>) => void;
}

export const AddButton: React.FC<AddButtonProps> = ({
  type,
  label,
  onClick,
  dataAddButton,
  className = '',
  epicId,
  versionId,
  featureId,
  onDrop
}) => {
  const ref = useRef<HTMLButtonElement>(null);
  const baseClass = `add-button add-${type}-btn`;
  const fullClass = className ? `${baseClass} ${className}` : baseClass;

  const handleClick = () => {
    console.log(`[DEBUG] AddButton clicked: type=${type}, label=${label}`);
    if (onClick) {
      console.log('[DEBUG] Calling onClick handler...');
      onClick();
      console.log('[DEBUG] onClick handler returned');
    } else {
      console.log('[DEBUG] No onClick handler provided, showing alert');
      alert(`${label} clicked!`);
    }
  };

  // AddButtonをdrop targetとして設定
  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    return dropTargetForElements({
      element,
      getData: () => ({
        type,
        id: `add-button-${type}-${epicId || 'none'}-${versionId || 'none'}-${featureId || 'none'}`,
        epicId,
        versionId,
        featureId,
        isAddButton: true
      }),
      canDrop: ({ source }) => {
        // 同じtypeのアイテムのみドロップ可能
        return source.data.type === type;
      },
      onDrop: ({ source }) => {
        if (onDrop) {
          onDrop(source.data);
        }
      }
    });
  }, [type, epicId, versionId, featureId, onDrop]);

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

