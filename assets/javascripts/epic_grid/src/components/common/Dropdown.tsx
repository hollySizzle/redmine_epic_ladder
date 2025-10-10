import React, { useEffect, useRef, useState } from 'react';

interface DropdownProps {
  trigger: React.ReactNode;
  children: React.ReactNode;
  align?: 'start' | 'end';
  className?: string;
}

export const Dropdown: React.FC<DropdownProps> = ({
  trigger,
  children,
  align = 'end',
  className = ''
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // 外側クリックで閉じる
  useEffect(() => {
    if (!isOpen) return;

    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    document.addEventListener('keydown', handleEscape);

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('keydown', handleEscape);
    };
  }, [isOpen]);

  return (
    <div className={`dropdown ${className}`} ref={dropdownRef}>
      <div className="dropdown-trigger" onClick={() => setIsOpen(!isOpen)}>
        {trigger}
      </div>

      {isOpen && (
        <div className={`dropdown-content dropdown-align-${align}`}>
          {children}
        </div>
      )}
    </div>
  );
};

interface DropdownSectionProps {
  children: React.ReactNode;
}

export const DropdownSection: React.FC<DropdownSectionProps> = ({ children }) => {
  return <div className="dropdown-section">{children}</div>;
};

interface DropdownLabelProps {
  children: React.ReactNode;
}

export const DropdownLabel: React.FC<DropdownLabelProps> = ({ children }) => {
  return <div className="dropdown-label">{children}</div>;
};

interface DropdownSeparatorProps {}

export const DropdownSeparator: React.FC<DropdownSeparatorProps> = () => {
  return <div className="dropdown-separator" />;
};
