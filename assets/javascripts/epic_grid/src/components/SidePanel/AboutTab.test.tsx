import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { AboutTab } from './AboutTab';

describe('AboutTab', () => {
  describe('Rendering', () => {
    it('should render the about tab container', () => {
      const { container } = render(<AboutTab />);
      const aboutTab = container.querySelector('.about-tab');

      expect(aboutTab).toBeInTheDocument();
    });

    it('should render the plugin title', () => {
      render(<AboutTab />);

      expect(screen.getByText('Epic Grid Plugin')).toBeInTheDocument();
    });

    it('should render the version information', () => {
      render(<AboutTab />);

      expect(screen.getByText('Version 0.8.1')).toBeInTheDocument();
    });
  });

  describe('Content Sections', () => {
    it('should render the overview section', () => {
      render(<AboutTab />);

      expect(screen.getByText('概要')).toBeInTheDocument();
      expect(screen.getByText(/RedmineのEpic\/Feature\/UserStoryを/)).toBeInTheDocument();
      expect(screen.getByText(/カンバンボード形式で管理するプラグインです。/)).toBeInTheDocument();
    });

    it('should render the features section', () => {
      render(<AboutTab />);

      expect(screen.getByText('主な機能')).toBeInTheDocument();
    });

    it('should render all feature list items', () => {
      render(<AboutTab />);

      expect(screen.getByText('Epic × Version のグリッドビュー')).toBeInTheDocument();
      expect(screen.getByText('ドラッグ&ドロップによる移動')).toBeInTheDocument();
      expect(screen.getByText('階層的なチケット管理')).toBeInTheDocument();
      expect(screen.getByText('リアルタイムフィルタリング')).toBeInTheDocument();
      expect(screen.getByText('詳細ペイン表示')).toBeInTheDocument();
    });

    it('should render the copyright footer', () => {
      render(<AboutTab />);

      expect(screen.getByText('© 2025 Redmine Epic Grid Plugin')).toBeInTheDocument();
    });
  });

  describe('Structure', () => {
    it('should have correct section structure', () => {
      const { container } = render(<AboutTab />);
      const sections = container.querySelectorAll('.about-tab__section');

      expect(sections.length).toBeGreaterThanOrEqual(4);
    });

    it('should have a feature list', () => {
      const { container } = render(<AboutTab />);
      const featureList = container.querySelector('.about-tab__feature-list');

      expect(featureList).toBeInTheDocument();
      expect(featureList?.tagName).toBe('UL');
    });

    it('should have 5 feature list items', () => {
      const { container } = render(<AboutTab />);
      const featureListItems = container.querySelectorAll('.about-tab__feature-list li');

      expect(featureListItems.length).toBe(5);
    });
  });
});
