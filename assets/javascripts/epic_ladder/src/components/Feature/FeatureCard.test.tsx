import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { FeatureCard } from './FeatureCard';
import { useStore } from '../../store/useStore';

vi.mock('../common/StatusIndicator', () => ({
  StatusIndicator: ({ status }: any) => (
    <span data-testid="status-indicator" data-status={status}>Status</span>
  )
}));

vi.mock('../UserStory/UserStoryGridForCard', () => ({
  UserStoryGridForCard: ({ featureId, storyIds }: any) => (
    <div data-testid="user-story-grid" data-feature-id={featureId}>
      {storyIds.length} stories
    </div>
  )
}));

vi.mock('../../hooks/useDraggableAndDropTarget', () => ({
  useDraggableAndDropTarget: () => ({ current: null })
}));

describe('FeatureCard', () => {
  const mockSetSelectedEntity = vi.fn();
  const mockToggleDetailPane = vi.fn();

  const mockFeature = {
    id: 'feature-1',
    title: 'Test Feature',
    status: 'open' as const,
    user_story_ids: ['us-1', 'us-2'],
  };

  const defaultState = {
    entities: {
      features: {
        'feature-1': mockFeature,
      },
    },
    setSelectedEntity: mockSetSelectedEntity,
    toggleDetailPane: mockToggleDetailPane,
    isDetailPaneVisible: false,
  };

  beforeEach(() => {
    vi.clearAllMocks();
    useStore.setState(defaultState as any);
  });

  describe('Rendering', () => {
    it('should render feature card', () => {
      render(<FeatureCard featureId="feature-1" />);

      expect(screen.getByText('Test Feature')).toBeInTheDocument();
    });

    it('should render null if feature not found', () => {
      const { container } = render(<FeatureCard featureId="non-existent" />);

      expect(container.firstChild).toBeNull();
    });

    it('should render status indicator', () => {
      render(<FeatureCard featureId="feature-1" />);

      expect(screen.getByTestId('status-indicator')).toBeInTheDocument();
      expect(screen.getByTestId('status-indicator')).toHaveAttribute('data-status', 'open');
    });

    it('should render user story grid', () => {
      render(<FeatureCard featureId="feature-1" />);

      expect(screen.getByTestId('user-story-grid')).toBeInTheDocument();
      expect(screen.getByTestId('user-story-grid')).toHaveAttribute('data-feature-id', 'feature-1');
      expect(screen.getByText('2 stories')).toBeInTheDocument();
    });
  });

  describe('Status Classes', () => {
    it('should apply feature-card class', () => {
      const { container } = render(<FeatureCard featureId="feature-1" />);

      expect(container.querySelector('.feature-card')).toBeInTheDocument();
    });

    it('should apply closed class when status is closed', () => {
      useStore.setState({
        ...defaultState,
        entities: {
          features: {
            'feature-1': { ...mockFeature, status: 'closed' },
          },
        },
      } as any);

      const { container } = render(<FeatureCard featureId="feature-1" />);

      expect(container.querySelector('.feature-card.closed')).toBeInTheDocument();
    });

    it('should not apply closed class when status is open', () => {
      const { container } = render(<FeatureCard featureId="feature-1" />);

      expect(container.querySelector('.feature-card')).toBeInTheDocument();
      expect(container.querySelector('.feature-card.closed')).not.toBeInTheDocument();
    });
  });

  describe('Header Click', () => {
    it('should select entity and toggle detail pane', () => {
      render(<FeatureCard featureId="feature-1" />);

      const header = screen.getByText('Test Feature').closest('.feature-header');
      fireEvent.click(header!);

      expect(mockToggleDetailPane).toHaveBeenCalled();
      expect(mockSetSelectedEntity).toHaveBeenCalledWith('issue', 'feature-1');
    });

    it('should not toggle detail pane if already visible', () => {
      useStore.setState({ ...defaultState, isDetailPaneVisible: true } as any);

      render(<FeatureCard featureId="feature-1" />);

      const header = screen.getByText('Test Feature').closest('.feature-header');
      fireEvent.click(header!);

      expect(mockToggleDetailPane).not.toHaveBeenCalled();
      expect(mockSetSelectedEntity).toHaveBeenCalledWith('issue', 'feature-1');
    });
  });

  describe('Data Attributes', () => {
    it('should set data-feature attribute', () => {
      const { container } = render(<FeatureCard featureId="feature-1" />);

      expect(container.querySelector('[data-feature="feature-1"]')).toBeInTheDocument();
    });
  });
});
