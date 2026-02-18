import React from 'react';
import { describe, it, expect } from 'vitest';
import { render } from '@testing-library/react';
import { Legend } from './Legend';

describe('Legend', () => {
  describe('Rendering', () => {
    it('should render the legend container', () => {
      const { container } = render(<Legend />);
      const legend = container.querySelector('.legend');

      expect(legend).toBeInTheDocument();
    });

    it('should render as a div element', () => {
      const { container } = render(<Legend />);
      const legend = container.querySelector('.legend');

      expect(legend?.tagName).toBe('DIV');
    });

    it('should have the legend class', () => {
      const { container } = render(<Legend />);
      const legend = container.querySelector('.legend');

      expect(legend).toHaveClass('legend');
    });
  });

  describe('Content', () => {
    it('should render empty content (commented items)', () => {
      const { container } = render(<Legend />);
      const legend = container.querySelector('.legend');

      // The legend items are commented out in the current implementation
      expect(legend?.children.length).toBe(0);
    });

    it('should not contain any visible legend items', () => {
      const { container } = render(<Legend />);
      const legendItems = container.querySelectorAll('.legend-item');

      expect(legendItems.length).toBe(0);
    });
  });

  describe('Structure', () => {
    it('should match the basic structure', () => {
      const { container } = render(<Legend />);

      expect(container.firstChild).toMatchSnapshot();
    });
  });
});
