import React from 'react';
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ListTab } from './ListTab';

describe('ListTab', () => {
  it('タイトルが表示される', () => {
    render(<ListTab />);

    expect(screen.getByText('Epic / Feature 一覧')).toBeInTheDocument();
  });

  it('プレースホルダーメッセージが表示される', () => {
    render(<ListTab />);

    expect(screen.getByText('🚧 一覧機能は実装予定です')).toBeInTheDocument();
  });

  it('実装予定機能リストが表示される', () => {
    render(<ListTab />);

    expect(screen.getByText('Epic階層ツリー表示')).toBeInTheDocument();
    expect(screen.getByText('Feature一覧表示')).toBeInTheDocument();
    expect(screen.getByText('クリックでグリッドにフォーカス')).toBeInTheDocument();
    expect(screen.getByText('折りたたみ/展開機能')).toBeInTheDocument();
    expect(screen.getByText('進捗バー表示')).toBeInTheDocument();
  });

  it('正しいクラス名が適用されている', () => {
    const { container } = render(<ListTab />);

    expect(container.querySelector('.list-tab')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__header')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__title')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__content')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__placeholder')).toBeInTheDocument();
    expect(container.querySelector('.list-tab__features')).toBeInTheDocument();
  });
});
