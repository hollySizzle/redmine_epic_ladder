import React, { useState, FormEvent } from 'react';
import { Dialog } from '@headlessui/react';

export interface VersionFormData {
  name: string;
  effective_date: string;
}

export interface VersionFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: VersionFormData) => void | Promise<void>;
}

export const VersionFormModal: React.FC<VersionFormModalProps> = ({ isOpen, onClose, onSubmit }) => {
  const [name, setName] = useState('');
  const [effectiveDate, setEffectiveDate] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    setIsSubmitting(true);
    try {
      await onSubmit({ name: name.trim(), effective_date: effectiveDate });
      // 成功したらフォームをリセット
      setName('');
      setEffectiveDate('');
      onClose();
    } catch (error) {
      // エラーは親コンポーネントで処理される想定
      console.error('Version form submission error:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    if (!isSubmitting) {
      setName('');
      setEffectiveDate('');
      onClose();
    }
  };

  return (
    <Dialog open={isOpen} onClose={handleClose} className="version-form-modal">
      <div className="modal-overlay" aria-hidden="true" />
      <div className="modal-container">
        <Dialog.Panel className="modal-panel">
          <Dialog.Title className="modal-title">新しいVersionを追加</Dialog.Title>

          <form onSubmit={handleSubmit} className="modal-form">
            <div className="form-group">
              <label htmlFor="version-name" className="form-label">
                Version名 <span className="required">*</span>
              </label>
              <input
                id="version-name"
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="form-input"
                placeholder="例: v1.0.0"
                required
                autoFocus
                disabled={isSubmitting}
                autoComplete="off"
                data-1p-ignore="true"
                data-lpignore="true"
                data-bwignore="true"
                data-protonpass-ignore="true"
              />
            </div>

            <div className="form-group">
              <label htmlFor="version-effective-date" className="form-label">
                期日
              </label>
              <input
                id="version-effective-date"
                type="date"
                value={effectiveDate}
                onChange={(e) => setEffectiveDate(e.target.value)}
                className="form-input"
                disabled={isSubmitting}
                autoComplete="off"
                data-1p-ignore="true"
                data-lpignore="true"
                data-bwignore="true"
                data-protonpass-ignore="true"
              />
            </div>

            <div className="modal-actions">
              <button
                type="button"
                onClick={handleClose}
                className="eg-button eg-button--secondary"
                disabled={isSubmitting}
              >
                キャンセル
              </button>
              <button
                type="submit"
                className="eg-button eg-button--primary"
                disabled={isSubmitting || !name.trim()}
              >
                {isSubmitting ? '作成中...' : '作成'}
              </button>
            </div>
          </form>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
};
