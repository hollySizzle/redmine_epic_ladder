import React from 'react';
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { SettingsDropdown } from './SettingsDropdown';

// Mock子コンポーネント
vi.mock('./Dropdown', () => ({
  Dropdown: ({ trigger, children }: any) => (
    <div data-testid="dropdown">
      {trigger}
      <div data-testid="dropdown-content">{children}</div>
    </div>
  ),
  DropdownLabel: ({ children }: any) => <div data-testid="dropdown-label">{children}</div>,
  DropdownSection: ({ children }: any) => <div data-testid="dropdown-section">{children}</div>,
  DropdownSeparator: () => <hr data-testid="dropdown-separator" />,
}));

vi.mock('./SortSelector', () => ({
  SortSelector: ({ type, label }: any) => (
    <div data-testid={`sort-selector-${type}`}>{label}</div>
  )
}));

vi.mock('./VerticalModeToggle', () => ({
  VerticalModeToggle: () => <div data-testid="vertical-mode-toggle">VerticalModeToggle</div>
}));

vi.mock('./AssignedToToggle', () => ({
  AssignedToToggle: () => <div data-testid="assigned-to-toggle">AssignedToToggle</div>
}));

vi.mock('./DueDateToggle', () => ({
  DueDateToggle: () => <div data-testid="due-date-toggle">DueDateToggle</div>
}));

vi.mock('./IssueIdToggle', () => ({
  IssueIdToggle: () => <div data-testid="issue-id-toggle">IssueIdToggle</div>
}));

vi.mock('./DetailPaneToggle', () => ({
  DetailPaneToggle: () => <div data-testid="detail-pane-toggle">DetailPaneToggle</div>
}));

describe('SettingsDropdown', () => {
  describe('Rendering', () => {
    it('should render settings button', () => {
      render(<SettingsDropdown />);

      expect(screen.getByTitle('表示設定')).toBeInTheDocument();
      expect(screen.getByText('⚙️ 表示設定')).toBeInTheDocument();
    });

    it('should render dropdown container', () => {
      render(<SettingsDropdown />);

      expect(screen.getByTestId('dropdown')).toBeInTheDocument();
    });
  });

  describe('Sort Settings', () => {
    it('should render sort settings label', () => {
      render(<SettingsDropdown />);

      expect(screen.getByText('ソート設定')).toBeInTheDocument();
    });

    it('should render epic sort selector', () => {
      render(<SettingsDropdown />);

      expect(screen.getByTestId('sort-selector-epic')).toBeInTheDocument();
      expect(screen.getByText('Epic&Feature並び替え')).toBeInTheDocument();
    });

    it('should render version sort selector', () => {
      render(<SettingsDropdown />);

      expect(screen.getByTestId('sort-selector-version')).toBeInTheDocument();
      expect(screen.getByText('Version並び替え')).toBeInTheDocument();
    });
  });

  describe('Display Options', () => {
    it('should render display options label', () => {
      render(<SettingsDropdown />);

      expect(screen.getByText('表示オプション')).toBeInTheDocument();
    });

    it('should render vertical mode toggle', () => {
      render(<SettingsDropdown />);

      expect(screen.getByTestId('vertical-mode-toggle')).toBeInTheDocument();
    });

    it('should render assigned to toggle', () => {
      render(<SettingsDropdown />);

      expect(screen.getByTestId('assigned-to-toggle')).toBeInTheDocument();
    });

    it('should render due date toggle', () => {
      render(<SettingsDropdown />);

      expect(screen.getByTestId('due-date-toggle')).toBeInTheDocument();
    });

    it('should render issue id toggle', () => {
      render(<SettingsDropdown />);

      expect(screen.getByTestId('issue-id-toggle')).toBeInTheDocument();
    });

    it('should render detail pane toggle', () => {
      render(<SettingsDropdown />);

      expect(screen.getByTestId('detail-pane-toggle')).toBeInTheDocument();
    });
  });

  describe('Structure', () => {
    it('should render separator between sort and display options', () => {
      render(<SettingsDropdown />);

      const separators = screen.getAllByTestId('dropdown-separator');
      expect(separators.length).toBeGreaterThanOrEqual(1);
    });

    it('should render dropdown sections', () => {
      render(<SettingsDropdown />);

      const sections = screen.getAllByTestId('dropdown-section');
      expect(sections.length).toBeGreaterThanOrEqual(7);
    });

    it('should render dropdown labels', () => {
      render(<SettingsDropdown />);

      const labels = screen.getAllByTestId('dropdown-label');
      expect(labels.length).toBe(2); // ソート設定 and 表示オプション
    });
  });
});
