// assets/javascripts/kanban/components/CreateVersionModal.jsx
import React, { useState } from 'react';

export const CreateVersionModal = ({ onSubmit, onClose }) => {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    effective_date: '',
    sharing: 'none'
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name.trim()) {
      setError('バージョン名は必須です');
      return;
    }

    setLoading(true);
    setError('');

    try {
      await onSubmit(formData);
    } catch (error) {
      setError(error.message || 'バージョン作成に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Escape') {
      onClose();
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="create-version-modal" onClick={(e) => e.stopPropagation()} onKeyDown={handleKeyDown}>
        <div className="modal-header">
          <h3>新しいVersionを作成</h3>
          <button
            className="modal-close-btn"
            onClick={onClose}
            type="button"
          >
            ×
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {error && (
              <div className="error-message" role="alert">
                {error}
              </div>
            )}

            <div className="form-group">
              <label htmlFor="version-name">
                バージョン名 <span className="required">*</span>
              </label>
              <input
                id="version-name"
                type="text"
                name="name"
                value={formData.name}
                onChange={handleInputChange}
                placeholder="例: v1.0.0"
                required
                autoFocus
                disabled={loading}
              />
            </div>

            <div className="form-group">
              <label htmlFor="version-description">説明</label>
              <textarea
                id="version-description"
                name="description"
                value={formData.description}
                onChange={handleInputChange}
                placeholder="このバージョンの概要を入力してください"
                rows={3}
                disabled={loading}
              />
            </div>

            <div className="form-group">
              <label htmlFor="version-due-date">リリース予定日</label>
              <input
                id="version-due-date"
                type="date"
                name="effective_date"
                value={formData.effective_date}
                onChange={handleInputChange}
                disabled={loading}
              />
            </div>

            <div className="form-group">
              <label htmlFor="version-sharing">共有設定</label>
              <select
                id="version-sharing"
                name="sharing"
                value={formData.sharing}
                onChange={handleInputChange}
                disabled={loading}
              >
                <option value="none">共有しない</option>
                <option value="descendants">サブプロジェクトと共有</option>
                <option value="hierarchy">プロジェクト階層と共有</option>
                <option value="tree">プロジェクトツリーと共有</option>
                <option value="system">すべてのプロジェクトと共有</option>
              </select>
            </div>
          </div>

          <div className="modal-footer">
            <button
              type="button"
              className="btn btn-secondary"
              onClick={onClose}
              disabled={loading}
            >
              キャンセル
            </button>
            <button
              type="submit"
              className="btn btn-primary"
              disabled={loading || !formData.name.trim()}
            >
              {loading ? '作成中...' : '作成'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};