import React from 'react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { DetailPane } from './DetailPane';
import { useStore } from '../../store/useStore';

describe('DetailPane', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useStore.setState({
      entities: {
        versions: {
          '1': { id: 1, name: 'v1.0' },
        },
      },
    } as any);

    // Mock setTimeout
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  describe('Empty State', () => {
    it('should render placeholder when no entity selected', () => {
      render(<DetailPane entity={null} projectId="1" />);

      expect(screen.getByText(/チケットまたはバージョンを選択すると詳細が表示されます/)).toBeInTheDocument();
    });

    it('should render placeholder icon', () => {
      const { container } = render(<DetailPane entity={null} projectId="1" />);

      expect(container.querySelector('.issue-detail-pane--empty')).toBeInTheDocument();
      expect(container.querySelector('.issue-detail-pane__placeholder-icon')).toBeInTheDocument();
    });
  });

  describe('Issue Display', () => {
    const issueEntity = { type: 'issue' as const, id: '123' };

    it('should render title for issue', () => {
      render(<DetailPane entity={issueEntity} projectId="1" />);

      expect(screen.getByText('チケット #123')).toBeInTheDocument();
    });

    it('should render iframe with correct src for issue', () => {
      const { container } = render(<DetailPane entity={issueEntity} projectId="1" />);

      const iframe = container.querySelector('iframe');
      expect(iframe).toBeInTheDocument();
      expect(iframe?.getAttribute('src')).toBe('/issues/123');
    });

    it('should render reload button', () => {
      render(<DetailPane entity={issueEntity} projectId="1" />);

      expect(screen.getByTitle('再読み込み')).toBeInTheDocument();
    });
  });

  describe('Version Display', () => {
    const versionEntity = { type: 'version' as const, id: '1' };

    it('should render title for version with name', () => {
      render(<DetailPane entity={versionEntity} projectId="1" />);

      expect(screen.getByText('バージョン: v1.0')).toBeInTheDocument();
    });

    it('should render title for version without name', () => {
      useStore.setState({ entities: { versions: {} } } as any);

      render(<DetailPane entity={{ type: 'version', id: '999' }} projectId="1" />);

      expect(screen.getByText('バージョン #999')).toBeInTheDocument();
    });

    it('should render iframe with correct src for version', () => {
      const { container } = render(<DetailPane entity={versionEntity} projectId="1" />);

      const iframe = container.querySelector('iframe');
      expect(iframe?.getAttribute('src')).toBe('/versions/1');
    });
  });

  describe('Loading State', () => {
    it('should show loading indicator initially', () => {
      render(<DetailPane entity={{ type: 'issue', id: '123' }} projectId="1" />);

      expect(screen.getByText('読み込み中...')).toBeInTheDocument();
    });

    it('should hide iframe while loading', () => {
      const { container } = render(<DetailPane entity={{ type: 'issue', id: '123' }} projectId="1" />);

      const iframe = container.querySelector('iframe') as HTMLIFrameElement;
      expect(iframe?.style.display).toBe('none');
    });

    it('should clear loading after timeout', async () => {
      render(<DetailPane entity={{ type: 'issue', id: '123' }} projectId="1" />);

      expect(screen.getByText('読み込み中...')).toBeInTheDocument();

      // Fast-forward 3 seconds
      vi.advanceTimersByTime(3000);

      // Use runAllTimers to flush all pending timers
      await vi.runAllTimersAsync();

      expect(screen.queryByText('読み込み中...')).not.toBeInTheDocument();
    });
  });

  describe('Reload Functionality', () => {
    it('should reload iframe when reload button clicked', () => {
      const { container } = render(<DetailPane entity={{ type: 'issue', id: '123' }} projectId="1" />);

      const reloadButton = screen.getByTitle('再読み込み');
      const iframe = container.querySelector('iframe') as HTMLIFrameElement;
      const originalSrc = iframe.src;

      fireEvent.click(reloadButton);

      // src should change (with timestamp)
      expect(iframe.src).not.toBe(originalSrc);
      expect(iframe.src).toContain('/issues/123?t=');
    });

    it('should show loading state after reload', () => {
      render(<DetailPane entity={{ type: 'issue', id: '123' }} projectId="1" />);

      // Clear initial loading
      vi.advanceTimersByTime(3000);

      const reloadButton = screen.getByTitle('再読み込み');
      fireEvent.click(reloadButton);

      expect(screen.getByText('読み込み中...')).toBeInTheDocument();
    });
  });

  describe('CSS Classes', () => {
    it('should apply correct classes to empty state', () => {
      const { container } = render(<DetailPane entity={null} projectId="1" />);

      expect(container.querySelector('.issue-detail-pane.issue-detail-pane--empty')).toBeInTheDocument();
    });

    it('should apply correct classes to active state', () => {
      const { container } = render(<DetailPane entity={{ type: 'issue', id: '123' }} projectId="1" />);

      expect(container.querySelector('.issue-detail-pane')).toBeInTheDocument();
      expect(container.querySelector('.issue-detail-pane--empty')).not.toBeInTheDocument();
    });
  });
});
