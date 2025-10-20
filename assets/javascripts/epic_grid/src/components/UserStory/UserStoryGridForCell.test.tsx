import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { UserStoryGridForCell } from './UserStoryGridForCell';
import { useStore } from '../../store/useStore';

vi.mock('./UserStory', () => ({
  UserStory: ({ storyId }: any) => <div data-testid={`user-story-${storyId}`}>UserStory {storyId}</div>
}));

vi.mock('../common/AddButton', () => ({
  AddButton: ({ onClick, label }: any) => (
    <button data-testid="add-button" onClick={onClick}>{label}</button>
  )
}));

vi.mock('../common/IssueFormModal', () => ({
  IssueFormModal: ({ isOpen, onClose, onSubmit }: any) => (
    isOpen ? (
      <div data-testid="issue-form-modal">
        <button data-testid="modal-close" onClick={onClose}>Close</button>
        <button data-testid="modal-submit" onClick={() => onSubmit({ subject: 'Test Story', description: '' })}>
          Submit
        </button>
      </div>
    ) : null
  )
}));

describe('UserStoryGridForCell', () => {
  const mockCreateUserStory = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
    useStore.setState({
      createUserStory: mockCreateUserStory,
      entities: {
        users: {
          '1': { id: 1, name: 'User 1' },
        },
      },
    } as any);
  });

  describe('Rendering', () => {
    it('should render user stories', () => {
      render(
        <UserStoryGridForCell
          epicId="epic-1"
          featureId="feature-1"
          versionId="version-1"
          storyIds={['us-1', 'us-2']}
        />
      );

      expect(screen.getByTestId('user-story-us-1')).toBeInTheDocument();
      expect(screen.getByTestId('user-story-us-2')).toBeInTheDocument();
    });

    it('should render add button', () => {
      render(
        <UserStoryGridForCell
          epicId="epic-1"
          featureId="feature-1"
          versionId="version-1"
          storyIds={[]}
        />
      );

      expect(screen.getByTestId('add-button')).toBeInTheDocument();
      expect(screen.getByText('+ Add User Story')).toBeInTheDocument();
    });
  });

  describe('Modal Interaction', () => {
    it('should open modal when add button clicked', () => {
      render(
        <UserStoryGridForCell
          epicId="epic-1"
          featureId="feature-1"
          versionId="version-1"
          storyIds={[]}
        />
      );

      fireEvent.click(screen.getByTestId('add-button'));

      expect(screen.getByTestId('issue-form-modal')).toBeInTheDocument();
    });

    it('should call createUserStory with version when form submitted', async () => {
      mockCreateUserStory.mockResolvedValue(undefined);

      render(
        <UserStoryGridForCell
          epicId="epic-1"
          featureId="feature-1"
          versionId="version-1"
          storyIds={[]}
        />
      );

      fireEvent.click(screen.getByTestId('add-button'));
      fireEvent.click(screen.getByTestId('modal-submit'));

      await waitFor(() => {
        expect(mockCreateUserStory).toHaveBeenCalledWith('feature-1', {
          subject: 'Test Story',
          description: '',
          parent_feature_id: 'feature-1',
          fixed_version_id: 'version-1',
          assigned_to_id: undefined,
        });
      });
    });

    it('should not include version id when versionId is "none"', async () => {
      mockCreateUserStory.mockResolvedValue(undefined);

      render(
        <UserStoryGridForCell
          epicId="epic-1"
          featureId="feature-1"
          versionId="none"
          storyIds={[]}
        />
      );

      fireEvent.click(screen.getByTestId('add-button'));
      fireEvent.click(screen.getByTestId('modal-submit'));

      await waitFor(() => {
        expect(mockCreateUserStory).toHaveBeenCalledWith('feature-1', {
          subject: 'Test Story',
          description: '',
          parent_feature_id: 'feature-1',
          fixed_version_id: undefined,
          assigned_to_id: undefined,
        });
      });
    });
  });
});
