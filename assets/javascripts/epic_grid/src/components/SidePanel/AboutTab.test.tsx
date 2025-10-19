import React from 'react';
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { AboutTab } from './AboutTab';

describe('AboutTab', () => {
  it('プラグインタイトルとバージョンが表示される', () => {
    render(<AboutTab />);

    expect(screen.getByText('Epic Grid Plugin')).toBeInTheDocument();
    expect(screen.getByText('Version 1.0.0')).toBeInTheDocument();
  });

  it('概要セクションが表示される', () => {
    render(<AboutTab />);

    expect(screen.getByText('概要')).toBeInTheDocument();
    expect(screen.getByText(/RedmineのEpic\/Feature\/UserStoryを/)).toBeInTheDocument();
    expect(screen.getByText(/カンバンボード形式で管理するプラグインです。/)).toBeInTheDocument();
  });

  it('主な機能リストが表示される', () => {
    render(<AboutTab />);

    expect(screen.getByText('主な機能')).toBeInTheDocument();
    expect(screen.getByText('Epic × Version のグリッドビュー')).toBeInTheDocument();
    expect(screen.getByText('ドラッグ&ドロップによる移動')).toBeInTheDocument();
    expect(screen.getByText('階層的なチケット管理')).toBeInTheDocument();
    expect(screen.getByText('リアルタイムフィルタリング')).toBeInTheDocument();
    expect(screen.getByText('詳細ペイン表示')).toBeInTheDocument();
  });

  it('フッターにコピーライトが表示される', () => {
    render(<AboutTab />);

    expect(screen.getByText('© 2025 Redmine Epic Grid Plugin')).toBeInTheDocument();
  });

  it('正しいクラス名が適用されている', () => {
    const { container } = render(<AboutTab />);

    expect(container.querySelector('.about-tab')).toBeInTheDocument();
    expect(container.querySelector('.about-tab__section')).toBeInTheDocument();
    expect(container.querySelector('.about-tab__title')).toBeInTheDocument();
    expect(container.querySelector('.about-tab__version')).toBeInTheDocument();
    expect(container.querySelector('.about-tab__subtitle')).toBeInTheDocument();
    expect(container.querySelector('.about-tab__description')).toBeInTheDocument();
    expect(container.querySelector('.about-tab__feature-list')).toBeInTheDocument();
    expect(container.querySelector('.about-tab__section--footer')).toBeInTheDocument();
    expect(container.querySelector('.about-tab__copyright')).toBeInTheDocument();
  });
});
