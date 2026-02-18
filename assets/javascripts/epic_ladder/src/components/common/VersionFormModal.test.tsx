import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { VersionFormModal, VersionFormData } from './VersionFormModal';

describe('VersionFormModal', () => {
  describe('Rendering', () => {
    it('should not render when isOpen is false', () => {
      const onClose = vi.fn();
      const onSubmit = vi.fn();

      render(
        <VersionFormModal isOpen={false} onClose={onClose} onSubmit={onSubmit} />
      );

      expect(screen.queryByText('新しいVersionを追加')).toBeNull();
    });

    it('should render when isOpen is true', () => {
      const onClose = vi.fn();
      const onSubmit = vi.fn();

      render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      expect(screen.getByText('新しいVersionを追加')).toBeTruthy();
    });

    it('should render version name input with required label', () => {
      const onClose = vi.fn();
      const onSubmit = vi.fn();

      render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      const nameLabel = screen.getByText(/Version名/);
      expect(nameLabel).toBeTruthy();
      expect(nameLabel.querySelector('.required')).toBeTruthy();

      const nameInput = screen.getByLabelText(/Version名/);
      expect(nameInput).toBeTruthy();
      expect(nameInput.getAttribute('type')).toBe('text');
      expect(nameInput.getAttribute('required')).toBe('');
    });

    it('should render due date input without required label', () => {
      const onClose = vi.fn();
      const onSubmit = vi.fn();

      render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      const dueDateLabel = screen.getByText('期日');
      expect(dueDateLabel).toBeTruthy();
      expect(dueDateLabel.querySelector('.required')).toBeNull();

      const dueDateInput = screen.getByLabelText('期日');
      expect(dueDateInput).toBeTruthy();
      expect(dueDateInput.getAttribute('type')).toBe('date');
      expect(dueDateInput.hasAttribute('required')).toBe(false);
    });

    it('should render cancel and submit buttons', () => {
      const onClose = vi.fn();
      const onSubmit = vi.fn();

      render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      expect(screen.getByText('キャンセル')).toBeTruthy();
      expect(screen.getByText('作成')).toBeTruthy();
    });
  });

  describe('Form submission', () => {
    it('should call onSubmit with form data when submit button is clicked', async () => {
      const user = userEvent.setup();
      const onClose = vi.fn();
      const onSubmit = vi.fn().mockResolvedValue(undefined);

      render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      const nameInput = screen.getByLabelText(/Version名/);
      const effectiveDateInput = screen.getByLabelText('期日');
      const submitButton = screen.getByText('作成');

      await user.type(nameInput, 'v1.0.0');
      await user.type(effectiveDateInput, '2025-12-31');
      await user.click(submitButton);

      expect(onSubmit).toHaveBeenCalledWith({
        name: 'v1.0.0',
        effective_date: '2025-12-31'
      });
      expect(onClose).toHaveBeenCalled();
    });

    it('should call onSubmit without effective_date when not provided', async () => {
      const user = userEvent.setup();
      const onClose = vi.fn();
      const onSubmit = vi.fn().mockResolvedValue(undefined);

      render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      const nameInput = screen.getByLabelText(/Version名/);
      const submitButton = screen.getByText('作成');

      await user.type(nameInput, 'v2.0.0');
      await user.click(submitButton);

      expect(onSubmit).toHaveBeenCalledWith({
        name: 'v2.0.0',
        effective_date: ''
      });
      expect(onClose).toHaveBeenCalled();
    });

    it('should trim whitespace from version name', async () => {
      const user = userEvent.setup();
      const onClose = vi.fn();
      const onSubmit = vi.fn().mockResolvedValue(undefined);

      render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      const nameInput = screen.getByLabelText(/Version名/);
      const submitButton = screen.getByText('作成');

      await user.type(nameInput, '  v1.0.0  ');
      await user.click(submitButton);

      expect(onSubmit).toHaveBeenCalledWith({
        name: 'v1.0.0',
        effective_date: ''
      });
    });

    it('should not call onSubmit when name is empty', async () => {
      const user = userEvent.setup();
      const onClose = vi.fn();
      const onSubmit = vi.fn();

      render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      const submitButton = screen.getByText('作成');
      await user.click(submitButton);

      expect(onSubmit).not.toHaveBeenCalled();
      expect(onClose).not.toHaveBeenCalled();
    });

    it('should not call onSubmit when name is only whitespace', async () => {
      const user = userEvent.setup();
      const onClose = vi.fn();
      const onSubmit = vi.fn();

      render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      const nameInput = screen.getByLabelText(/Version名/);
      const submitButton = screen.getByText('作成');

      await user.type(nameInput, '   ');
      await user.click(submitButton);

      expect(onSubmit).not.toHaveBeenCalled();
      expect(onClose).not.toHaveBeenCalled();
    });

    it('should reset form after successful submission', async () => {
      const user = userEvent.setup();
      const onClose = vi.fn();
      const onSubmit = vi.fn().mockResolvedValue(undefined);

      const { rerender } = render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      const nameInput = screen.getByLabelText(/Version名/) as HTMLInputElement;
      const effectiveDateInput = screen.getByLabelText('期日') as HTMLInputElement;
      const submitButton = screen.getByText('作成');

      await user.type(nameInput, 'v1.0.0');
      await user.type(effectiveDateInput, '2025-12-31');
      await user.click(submitButton);

      // モーダルを再度開く
      rerender(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      expect(nameInput.value).toBe('');
      expect(effectiveDateInput.value).toBe('');
    });

    it('should not close modal when submission fails', async () => {
      const user = userEvent.setup();
      const onClose = vi.fn();
      const onSubmit = vi.fn().mockRejectedValue(new Error('API Error'));

      render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      const nameInput = screen.getByLabelText(/Version名/);
      const submitButton = screen.getByText('作成');

      await user.type(nameInput, 'v1.0.0');
      await user.click(submitButton);

      expect(onSubmit).toHaveBeenCalled();
      expect(onClose).not.toHaveBeenCalled();
    });
  });

  describe('Cancel functionality', () => {
    it('should call onClose when cancel button is clicked', async () => {
      const user = userEvent.setup();
      const onClose = vi.fn();
      const onSubmit = vi.fn();

      render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      const cancelButton = screen.getByText('キャンセル');
      await user.click(cancelButton);

      expect(onClose).toHaveBeenCalled();
      expect(onSubmit).not.toHaveBeenCalled();
    });

    it('should reset form when cancelled', async () => {
      const user = userEvent.setup();
      const onClose = vi.fn();
      const onSubmit = vi.fn();

      const { rerender } = render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      const nameInput = screen.getByLabelText(/Version名/) as HTMLInputElement;
      const cancelButton = screen.getByText('キャンセル');

      await user.type(nameInput, 'v1.0.0');
      await user.click(cancelButton);

      // モーダルを再度開く
      rerender(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      expect(nameInput.value).toBe('');
    });
  });

  describe('Disabled states', () => {
    it('should disable inputs during submission', async () => {
      const user = userEvent.setup();
      const onClose = vi.fn();
      let resolveSubmit: () => void;
      const onSubmit = vi.fn(() => new Promise<void>((resolve) => {
        resolveSubmit = resolve;
      }));

      render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      const nameInput = screen.getByLabelText(/Version名/) as HTMLInputElement;
      const effectiveDateInput = screen.getByLabelText('期日') as HTMLInputElement;
      const submitButton = screen.getByText('作成') as HTMLButtonElement;

      await user.type(nameInput, 'v1.0.0');
      await user.click(submitButton);

      expect(nameInput.disabled).toBe(true);
      expect(effectiveDateInput.disabled).toBe(true);
      expect(submitButton.disabled).toBe(true);

      resolveSubmit!();
    });

    it('should show "作成中..." text during submission', async () => {
      const user = userEvent.setup();
      const onClose = vi.fn();
      let resolveSubmit: () => void;
      const onSubmit = vi.fn(() => new Promise<void>((resolve) => {
        resolveSubmit = resolve;
      }));

      render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      const nameInput = screen.getByLabelText(/Version名/);
      const submitButton = screen.getByText('作成');

      await user.type(nameInput, 'v1.0.0');
      await user.click(submitButton);

      expect(screen.getByText('作成中...')).toBeTruthy();

      resolveSubmit!();
    });

    it('should disable submit button when name is empty', () => {
      const onClose = vi.fn();
      const onSubmit = vi.fn();

      render(
        <VersionFormModal isOpen={true} onClose={onClose} onSubmit={onSubmit} />
      );

      const submitButton = screen.getByText('作成') as HTMLButtonElement;
      expect(submitButton.disabled).toBe(true);
    });
  });
});
