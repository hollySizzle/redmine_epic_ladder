import React from 'react';
import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Dropdown, DropdownSection, DropdownLabel, DropdownSeparator } from './Dropdown';

describe('Dropdown', () => {
  beforeEach(() => {
    // Cleanup
  });

  describe('Basic Rendering', () => {
    it('トリガーが表示される', () => {
      render(
        <Dropdown trigger={<button>Open Menu</button>}>
          <div>Content</div>
        </Dropdown>
      );
      expect(screen.getByText('Open Menu')).toBeInTheDocument();
    });

    it('初期状態ではコンテンツが表示されない', () => {
      render(
        <Dropdown trigger={<button>Open</button>}>
          <div>Hidden Content</div>
        </Dropdown>
      );
      expect(screen.queryByText('Hidden Content')).not.toBeInTheDocument();
    });

    it('カスタムクラスが適用される', () => {
      const { container } = render(
        <Dropdown trigger={<button>Open</button>} className="custom-dropdown">
          <div>Content</div>
        </Dropdown>
      );
      const dropdown = container.querySelector('.dropdown');
      expect(dropdown).toHaveClass('custom-dropdown');
    });
  });

  describe('Opening and Closing', () => {
    it('トリガークリックでコンテンツが表示される', () => {
      render(
        <Dropdown trigger={<button>Open</button>}>
          <div>Menu Content</div>
        </Dropdown>
      );

      const trigger = screen.getByText('Open');
      fireEvent.click(trigger);

      expect(screen.getByText('Menu Content')).toBeInTheDocument();
    });

    it('再度トリガークリックでコンテンツが非表示になる', () => {
      render(
        <Dropdown trigger={<button>Toggle</button>}>
          <div>Toggleable Content</div>
        </Dropdown>
      );

      const trigger = screen.getByText('Toggle');

      // Open
      fireEvent.click(trigger);
      expect(screen.getByText('Toggleable Content')).toBeInTheDocument();

      // Close
      fireEvent.click(trigger);
      expect(screen.queryByText('Toggleable Content')).not.toBeInTheDocument();
    });
  });

  describe('Alignment', () => {
    it('デフォルトではalign=endが適用される', () => {
      const { container } = render(
        <Dropdown trigger={<button>Open</button>}>
          <div>Content</div>
        </Dropdown>
      );

      const trigger = screen.getByText('Open');
      fireEvent.click(trigger);

      const content = container.querySelector('.dropdown-content');
      expect(content).toHaveClass('dropdown-align-end');
    });

    it('align="start"が適用される', () => {
      const { container } = render(
        <Dropdown trigger={<button>Open</button>} align="start">
          <div>Content</div>
        </Dropdown>
      );

      const trigger = screen.getByText('Open');
      fireEvent.click(trigger);

      const content = container.querySelector('.dropdown-content');
      expect(content).toHaveClass('dropdown-align-start');
    });
  });

  describe('Outside Click', () => {
    it('外側クリックでドロップダウンが閉じる', () => {
      render(
        <div>
          <Dropdown trigger={<button>Open</button>}>
            <div>Content</div>
          </Dropdown>
          <div data-testid="outside">Outside</div>
        </div>
      );

      const trigger = screen.getByText('Open');
      fireEvent.click(trigger);
      expect(screen.getByText('Content')).toBeInTheDocument();

      const outside = screen.getByTestId('outside');
      fireEvent.mouseDown(outside);
      expect(screen.queryByText('Content')).not.toBeInTheDocument();
    });

    it('ドロップダウン内クリックでは閉じない', () => {
      render(
        <Dropdown trigger={<button>Open</button>}>
          <div data-testid="inside">Inside Content</div>
        </Dropdown>
      );

      const trigger = screen.getByText('Open');
      fireEvent.click(trigger);

      const inside = screen.getByTestId('inside');
      fireEvent.mouseDown(inside);
      expect(screen.getByText('Inside Content')).toBeInTheDocument();
    });
  });

  describe('Escape Key', () => {
    it('Escapeキーでドロップダウンが閉じる', () => {
      render(
        <Dropdown trigger={<button>Open</button>}>
          <div>Closeable Content</div>
        </Dropdown>
      );

      const trigger = screen.getByText('Open');
      fireEvent.click(trigger);
      expect(screen.getByText('Closeable Content')).toBeInTheDocument();

      fireEvent.keyDown(document, { key: 'Escape' });
      expect(screen.queryByText('Closeable Content')).not.toBeInTheDocument();
    });

    it('閉じているときはEscapeキーで何も起きない', () => {
      render(
        <Dropdown trigger={<button>Open</button>}>
          <div>Content</div>
        </Dropdown>
      );

      fireEvent.keyDown(document, { key: 'Escape' });
      expect(screen.queryByText('Content')).not.toBeInTheDocument();
    });
  });
});

describe('DropdownSection', () => {
  it('子要素が表示される', () => {
    render(<DropdownSection><div>Section Content</div></DropdownSection>);
    expect(screen.getByText('Section Content')).toBeInTheDocument();
  });

  it('dropdown-sectionクラスが適用される', () => {
    const { container } = render(<DropdownSection><div>Content</div></DropdownSection>);
    const section = container.querySelector('.dropdown-section');
    expect(section).toBeInTheDocument();
  });
});

describe('DropdownLabel', () => {
  it('ラベルテキストが表示される', () => {
    render(<DropdownLabel>Label Text</DropdownLabel>);
    expect(screen.getByText('Label Text')).toBeInTheDocument();
  });

  it('dropdown-labelクラスが適用される', () => {
    const { container } = render(<DropdownLabel>Label</DropdownLabel>);
    const label = container.querySelector('.dropdown-label');
    expect(label).toBeInTheDocument();
  });
});

describe('DropdownSeparator', () => {
  it('セパレーターが表示される', () => {
    const { container } = render(<DropdownSeparator />);
    const separator = container.querySelector('.dropdown-separator');
    expect(separator).toBeInTheDocument();
  });
});
