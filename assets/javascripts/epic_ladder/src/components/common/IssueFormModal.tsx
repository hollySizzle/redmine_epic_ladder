import React, { useState, FormEvent } from 'react';
import { Dialog } from '@headlessui/react';
import { User } from '../../types/normalized-api';

export interface IssueFormData {
  subject: string;
  description: string;
  assigned_to_id?: number;
}

export interface IssueFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: IssueFormData) => void | Promise<void>;
  title: string;
  subjectLabel?: string;
  subjectPlaceholder?: string;
  // 担当者フィールド関連
  showAssignee?: boolean;
  users?: User[];
  defaultAssigneeId?: number;
}

export const IssueFormModal: React.FC<IssueFormModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  title,
  subjectLabel = '件名',
  subjectPlaceholder = '',
  showAssignee = false,
  users = [],
  defaultAssigneeId
}) => {
  const [subject, setSubject] = useState('');
  const [description, setDescription] = useState('');
  const [assignedToId, setAssignedToId] = useState<number | undefined>(defaultAssigneeId);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!subject.trim()) return;

    setIsSubmitting(true);
    try {
      await onSubmit({
        subject: subject.trim(),
        description: description.trim(),
        assigned_to_id: assignedToId
      });
      // 成功したらフォームをリセット
      setSubject('');
      setDescription('');
      setAssignedToId(defaultAssigneeId);
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
      setAssignedToId(defaultAssigneeId);
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

            {showAssignee && (
              <div className="form-group">
                <label htmlFor="issue-assignee" className="form-label">
                  担当者
                </label>
                <select
                  id="issue-assignee"
                  value={assignedToId ?? ''}
                  onChange={(e) => setAssignedToId(e.target.value ? Number(e.target.value) : undefined)}
                  className="form-select"
                  disabled={isSubmitting}
                >
                  <option value="">未割り当て</option>
                  {users.map((user) => (
                    <option key={user.id} value={user.id}>
                      {user.lastname} {user.firstname}
                    </option>
                  ))}
                </select>
              </div>
            )}

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
