import React, { useState, FormEvent } from 'react';
import { Dialog } from '@headlessui/react';
import './IssueFormModal.css';

export interface IssueFormData {
  subject: string;
  description: string;
}

export interface IssueFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: IssueFormData) => void | Promise<void>;
  title: string;
  subjectLabel?: string;
  subjectPlaceholder?: string;
}

export const IssueFormModal: React.FC<IssueFormModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  title,
  subjectLabel = '件名',
  subjectPlaceholder = ''
}) => {
  const [subject, setSubject] = useState('');
  const [description, setDescription] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!subject.trim()) return;

    setIsSubmitting(true);
    try {
      await onSubmit({ subject: subject.trim(), description: description.trim() });
      // 成功したらフォームをリセット
      setSubject('');
      setDescription('');
      onClose();
    } catch (error) {
      // エラーは親コンポーネントで処理される想定
      console.error('Issue form submission error:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    if (!isSubmitting) {
      setSubject('');
      setDescription('');
      onClose();
    }
  };

  return (
    <Dialog open={isOpen} onClose={handleClose} className="issue-form-modal">
      <div className="modal-overlay" aria-hidden="true" />
      <div className="modal-container">
        <Dialog.Panel className="modal-panel">
          <Dialog.Title className="modal-title">{title}</Dialog.Title>

          <form onSubmit={handleSubmit} className="modal-form">
            <div className="form-group">
              <label htmlFor="issue-subject" className="form-label">
                {subjectLabel} <span className="required">*</span>
              </label>
              <input
                id="issue-subject"
                type="text"
                value={subject}
                onChange={(e) => setSubject(e.target.value)}
                className="form-input"
                placeholder={subjectPlaceholder}
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
              <label htmlFor="issue-description" className="form-label">
                説明
              </label>
              <textarea
                id="issue-description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="form-textarea"
                rows={5}
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
                className="btn-cancel"
                disabled={isSubmitting}
              >
                キャンセル
              </button>
              <button
                type="submit"
                className="btn-submit"
                disabled={isSubmitting || !subject.trim()}
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
