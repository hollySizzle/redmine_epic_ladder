import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { IssueFormModal } from './IssueFormModal';

describe('IssueFormModal', () => {
  const onClose = vi.fn();
  const onSubmit = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Rendering', () => {
    it('should render when isOpen is true', () => {
      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      expect(screen.getByText('テストタイトル')).toBeInTheDocument();
      expect(screen.getByLabelText(/件名/)).toBeInTheDocument();
      expect(screen.getByLabelText('説明')).toBeInTheDocument();
    });

    it('should not render when isOpen is false', () => {
      render(
        <IssueFormModal
          isOpen={false}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      expect(screen.queryByText('テストタイトル')).not.toBeInTheDocument();
    });

    it('should render subject input with required label', () => {
      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      const subjectLabel = screen.getByText(/件名/);
      expect(subjectLabel).toBeInTheDocument();
      expect(subjectLabel.querySelector('.required')).toBeInTheDocument();
    });

    it('should render description textarea without required label', () => {
      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      const descriptionLabel = screen.getByText('説明');
      expect(descriptionLabel).toBeInTheDocument();
      expect(descriptionLabel.querySelector('.required')).not.toBeInTheDocument();
    });

    it('should render cancel and submit buttons', () => {
      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      expect(screen.getByText('キャンセル')).toBeInTheDocument();
      expect(screen.getByText('作成')).toBeInTheDocument();
    });

    it('should render custom subject label', () => {
      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
          subjectLabel="Epic名"
        />
      );

      expect(screen.getByLabelText(/Epic名/)).toBeInTheDocument();
    });

    it('should render with placeholder', () => {
      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
          subjectPlaceholder="例: テスト"
        />
      );

      const input = screen.getByPlaceholderText('例: テスト');
      expect(input).toBeInTheDocument();
    });
  });

  describe('Form submission', () => {
    it('should call onSubmit with form data when submit button is clicked', async () => {
      const user = userEvent.setup();
      onSubmit.mockResolvedValue(undefined);

      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      await user.type(screen.getByLabelText(/件名/), 'テストEpic');
      await user.type(screen.getByLabelText('説明'), 'テスト説明');
      await user.click(screen.getByText('作成'));

      expect(onSubmit).toHaveBeenCalledWith({
        subject: 'テストEpic',
        description: 'テスト説明'
      });
    });

    it('should trim whitespace from subject', async () => {
      const user = userEvent.setup();
      onSubmit.mockResolvedValue(undefined);

      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      await user.type(screen.getByLabelText(/件名/), '  テストEpic  ');
      await user.click(screen.getByText('作成'));

      expect(onSubmit).toHaveBeenCalledWith({
        subject: 'テストEpic',
        description: ''
      });
    });

    it('should trim whitespace from description', async () => {
      const user = userEvent.setup();
      onSubmit.mockResolvedValue(undefined);

      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      await user.type(screen.getByLabelText(/件名/), 'テストEpic');
      await user.type(screen.getByLabelText('説明'), '  テスト説明  ');
      await user.click(screen.getByText('作成'));

      expect(onSubmit).toHaveBeenCalledWith({
        subject: 'テストEpic',
        description: 'テスト説明'
      });
    });

    it('should allow empty description', async () => {
      const user = userEvent.setup();
      onSubmit.mockResolvedValue(undefined);

      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      await user.type(screen.getByLabelText(/件名/), 'テストEpic');
      await user.click(screen.getByText('作成'));

      expect(onSubmit).toHaveBeenCalledWith({
        subject: 'テストEpic',
        description: ''
      });
    });

    it('should close modal and reset form after successful submission', async () => {
      const user = userEvent.setup();
      onSubmit.mockResolvedValue(undefined);

      const { rerender } = render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      await user.type(screen.getByLabelText(/件名/), 'テストEpic');
      await user.type(screen.getByLabelText('説明'), 'テスト説明');
      await user.click(screen.getByText('作成'));

      await vi.waitFor(() => {
        expect(onClose).toHaveBeenCalled();
      });

      // Re-open modal to check if form is reset
      rerender(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      const subjectInput = screen.getByLabelText(/件名/) as HTMLInputElement;
      const descriptionInput = screen.getByLabelText('説明') as HTMLTextAreaElement;
      expect(subjectInput.value).toBe('');
      expect(descriptionInput.value).toBe('');
    });

    it('should not close modal when submission fails', async () => {
      const user = userEvent.setup();
      onSubmit.mockRejectedValue(new Error('API Error'));

      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      await user.type(screen.getByLabelText(/件名/), 'テストEpic');
      await user.click(screen.getByText('作成'));

      await vi.waitFor(() => {
        expect(onSubmit).toHaveBeenCalled();
      });

      expect(onClose).not.toHaveBeenCalled();
    });
  });

  describe('Cancel functionality', () => {
    it('should call onClose when cancel button is clicked', async () => {
      const user = userEvent.setup();

      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      await user.click(screen.getByText('キャンセル'));

      expect(onClose).toHaveBeenCalled();
      expect(onSubmit).not.toHaveBeenCalled();
    });

    it('should reset form when cancel button is clicked', async () => {
      const user = userEvent.setup();

      const { rerender } = render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      await user.type(screen.getByLabelText(/件名/), 'テストEpic');
      await user.type(screen.getByLabelText('説明'), 'テスト説明');
      await user.click(screen.getByText('キャンセル'));

      // Re-open modal
      rerender(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      const subjectInput = screen.getByLabelText(/件名/) as HTMLInputElement;
      const descriptionInput = screen.getByLabelText('説明') as HTMLTextAreaElement;
      expect(subjectInput.value).toBe('');
      expect(descriptionInput.value).toBe('');
    });
  });

  describe('Disabled states', () => {
    it('should disable inputs during submission', async () => {
      const user = userEvent.setup();
      onSubmit.mockImplementation(() => new Promise(() => {})); // Never resolves

      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      await user.type(screen.getByLabelText(/件名/), 'テストEpic');
      const submitButton = screen.getByText('作成');
      await user.click(submitButton);

      await vi.waitFor(() => {
        const subjectInput = screen.getByLabelText(/件名/) as HTMLInputElement;
        const descriptionInput = screen.getByLabelText('説明') as HTMLTextAreaElement;
        expect(subjectInput).toBeDisabled();
        expect(descriptionInput).toBeDisabled();
      });
    });

    it('should show "作成中..." text during submission', async () => {
      const user = userEvent.setup();
      onSubmit.mockImplementation(() => new Promise(() => {})); // Never resolves

      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      await user.type(screen.getByLabelText(/件名/), 'テストEpic');
      const submitButton = screen.getByText('作成');
      await user.click(submitButton);

      await vi.waitFor(() => {
        expect(screen.getByText('作成中...')).toBeInTheDocument();
      });
    });

    it('should disable submit button when subject is empty', () => {
      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      const submitButton = screen.getByText('作成');
      expect(submitButton).toBeDisabled();
    });

    it('should enable submit button when subject is filled', async () => {
      const user = userEvent.setup();

      render(
        <IssueFormModal
          isOpen={true}
          onClose={onClose}
          onSubmit={onSubmit}
          title="テストタイトル"
        />
      );

      const submitButton = screen.getByText('作成');
      expect(submitButton).toBeDisabled();

      await user.type(screen.getByLabelText(/件名/), 'テストEpic');

      expect(submitButton).not.toBeDisabled();
    });
  });
});
