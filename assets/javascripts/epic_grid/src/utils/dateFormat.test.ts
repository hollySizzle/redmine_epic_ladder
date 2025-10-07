import { describe, it, expect } from 'vitest';
import { formatDateRange, formatDate } from './dateFormat';

describe('formatDateRange', () => {
  describe('Both dates present', () => {
    it('should format date range within the same month', () => {
      expect(formatDateRange('2025-12-20', '2025-12-25')).toBe('12/20~12/25');
    });

    it('should format date range across different months in the same year', () => {
      expect(formatDateRange('2025-11-25', '2025-12-30')).toBe('11/25~12/30');
    });

    it('should format date range across years in mm/dd format', () => {
      expect(formatDateRange('2024-12-28', '2025-01-05')).toBe('12/28~1/5');
      expect(formatDateRange('2025-12-31', '2026-01-01')).toBe('12/31~1/1');
    });

    it('should handle single-digit months and days', () => {
      expect(formatDateRange('2025-01-05', '2025-02-09')).toBe('1/5~2/9');
      expect(formatDateRange('2025-03-01', '2025-04-03')).toBe('3/1~4/3');
    });

    it('should handle double-digit months and days', () => {
      expect(formatDateRange('2025-10-15', '2025-11-20')).toBe('10/15~11/20');
    });
  });

  describe('Only start date present', () => {
    it('should format as "mm/dd~" when only start_date is provided', () => {
      expect(formatDateRange('2025-12-20', null)).toBe('12/20~');
      expect(formatDateRange('2025-12-20', undefined)).toBe('12/20~');
    });

    it('should treat empty string due_date as missing', () => {
      expect(formatDateRange('2025-12-20', '')).toBe('12/20~');
    });

    it('should handle single-digit month/day for start date only', () => {
      expect(formatDateRange('2025-01-05', null)).toBe('1/5~');
    });
  });

  describe('Only due date present', () => {
    it('should format as "~mm/dd" when only due_date is provided', () => {
      expect(formatDateRange(null, '2025-12-25')).toBe('~12/25');
      expect(formatDateRange(undefined, '2025-12-25')).toBe('~12/25');
    });

    it('should treat empty string start_date as missing', () => {
      expect(formatDateRange('', '2025-12-25')).toBe('~12/25');
    });

    it('should handle single-digit month/day for due date only', () => {
      expect(formatDateRange(null, '2025-01-05')).toBe('~1/5');
    });
  });

  describe('No dates present', () => {
    it('should return null when both dates are null', () => {
      expect(formatDateRange(null, null)).toBeNull();
    });

    it('should return null when both dates are undefined', () => {
      expect(formatDateRange(undefined, undefined)).toBeNull();
    });

    it('should return null when both dates are empty strings', () => {
      expect(formatDateRange('', '')).toBeNull();
    });

    it('should return null when start is null and due is empty string', () => {
      expect(formatDateRange(null, '')).toBeNull();
    });

    it('should return null when start is empty string and due is null', () => {
      expect(formatDateRange('', null)).toBeNull();
    });
  });

  describe('Edge cases', () => {
    it('should handle leap year dates', () => {
      expect(formatDateRange('2024-02-28', '2024-02-29')).toBe('2/28~2/29');
    });

    it('should handle month boundaries', () => {
      expect(formatDateRange('2025-01-31', '2025-02-01')).toBe('1/31~2/1');
      expect(formatDateRange('2025-03-31', '2025-04-01')).toBe('3/31~4/1');
    });

    it('should handle year end and new year', () => {
      expect(formatDateRange('2025-12-31', '2026-01-01')).toBe('12/31~1/1');
    });
  });
});

describe('formatDate', () => {
  describe('Valid date strings', () => {
    it('should format date in mm/dd format', () => {
      expect(formatDate('2025-12-25')).toBe('12/25');
      expect(formatDate('2025-01-05')).toBe('1/5');
    });

    it('should handle single-digit months and days', () => {
      expect(formatDate('2025-01-01')).toBe('1/1');
      expect(formatDate('2025-03-09')).toBe('3/9');
    });

    it('should handle double-digit months and days', () => {
      expect(formatDate('2025-10-15')).toBe('10/15');
      expect(formatDate('2025-12-31')).toBe('12/31');
    });

    it('should handle year boundaries', () => {
      expect(formatDate('2025-01-01')).toBe('1/1');
      expect(formatDate('2025-12-31')).toBe('12/31');
    });
  });

  describe('Null/undefined/empty handling', () => {
    it('should return null when date is null', () => {
      expect(formatDate(null)).toBeNull();
    });

    it('should return null when date is undefined', () => {
      expect(formatDate(undefined)).toBeNull();
    });

    it('should return null when date is empty string', () => {
      expect(formatDate('')).toBeNull();
    });
  });
});
