import React from 'react';

interface AddButtonProps {
  type: 'epic' | 'version' | 'feature' | 'user-story' | 'task' | 'test' | 'bug';
  label: string;
  onClick?: () => void;
  dataAddButton?: string;
  className?: string;
}

export const AddButton: React.FC<AddButtonProps> = ({
  type,
  label,
  onClick,
  dataAddButton,
  className = ''
}) => {
  const baseClass = `add-button add-${type}-btn`;
  const fullClass = className ? `${baseClass} ${className}` : baseClass;

  const handleClick = () => {
    if (onClick) {
      onClick();
    } else {
      alert(`${label} clicked!`);
    }
  };

  return (
    <button
      className={fullClass}
      data-add-button={dataAddButton}
      onClick={handleClick}
    >
      {label}
    </button>
  );
};
