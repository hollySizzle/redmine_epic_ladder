import React from 'react';
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { StatusIndicator } from './StatusIndicator';

describe('StatusIndicator', () => {
  describe('Rendering', () => {
    it('should render with open status', () => {
      const { container } = render(<StatusIndicator status="open" />);
      const indicator = container.querySelector('.status-indicator');

      expect(indicator).toBeInTheDocument();
      expect(indicator).toHaveClass('status-indicator');
      expect(indicator).toHaveClass('status-open');
    });

    it('should render with closed status', () => {
      const { container } = render(<StatusIndicator status="closed" />);
      const indicator = container.querySelector('.status-indicator');

      expect(indicator).toBeInTheDocument();
      expect(indicator).toHaveClass('status-indicator');
      expect(indicator).toHaveClass('status-closed');
    });

    it('should render with in_progress status', () => {
      const { container } = render(<StatusIndicator status="in_progress" />);
      const indicator = container.querySelector('.status-indicator');

      expect(indicator).toBeInTheDocument();
      expect(indicator).toHaveClass('status-indicator');
      expect(indicator).toHaveClass('status-in_progress');
    });
  });

  describe('CSS Classes', () => {
    it('should apply correct class combination for open status', () => {
      const { container } = render(<StatusIndicator status="open" />);
      const indicator = container.querySelector('.status-indicator.status-open');

      expect(indicator).toBeInTheDocument();
    });

    it('should apply correct class combination for closed status', () => {
      const { container } = render(<StatusIndicator status="closed" />);
      const indicator = container.querySelector('.status-indicator.status-closed');

      expect(indicator).toBeInTheDocument();
    });

    it('should apply correct class combination for in_progress status', () => {
      const { container } = render(<StatusIndicator status="in_progress" />);
      const indicator = container.querySelector('.status-indicator.status-in_progress');

      expect(indicator).toBeInTheDocument();
    });
  });

  describe('Structure', () => {
    it('should render as a span element', () => {
      const { container } = render(<StatusIndicator status="open" />);
      const indicator = container.querySelector('span');

      expect(indicator).toBeInTheDocument();
      expect(indicator?.tagName).toBe('SPAN');
    });

    it('should not render any text content', () => {
      const { container } = render(<StatusIndicator status="open" />);
      const indicator = container.querySelector('.status-indicator');

      expect(indicator?.textContent).toBe('');
    });
  });
});
