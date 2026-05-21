import { renderHook, act } from '@testing-library/react';
import { useZoomConfigDHMLX } from '../../hooks/useZoomConfigDHMLX';
import * as cookies from '../../utils/cookies';

// Cookieユーティリティのモック
jest.mock('../../utils/cookies');

describe('useZoomConfigDHMLX', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    cookies.getCookie.mockReturnValue(null);
    cookies.setCookie.mockImplementation(() => {});
  });

  describe('F001/F002: ズーム機能', () => {
    it('初期状態でデフォルトのズームレベル（day）を返す', () => {
      const { result } = renderHook(() => useZoomConfigDHMLX());
      
      expect(result.current.level).toBe('day');
      expect(result.current.config).toEqual({
        scale_unit: 'day',
        date_scale: '%j',
        subscales: [
          { unit: 'month', step: 1, date: '%Y年%n月' }
        ],
        scale_height: 50,
        min_column_width: 50
      });
    });

    it('Cookieから保存されたズームレベルを読み込む', () => {
      cookies.getCookie.mockReturnValue('week');
      
      const { result } = renderHook(() => useZoomConfigDHMLX());
      
      expect(result.current.level).toBe('week');
      expect(cookies.getCookie).toHaveBeenCalledWith('zoomLevel');
    });

    it('各ズームレベルの設定を正しく返す', () => {
      const { result } = renderHook(() => useZoomConfigDHMLX());
      
      // 時間レベル
      act(() => {
        result.current.setLevel('hour');
      });
      expect(result.current.config).toMatchObject({
        scale_unit: 'hour',
        date_scale: '%H:00',
        subscales: [
          { unit: 'day', step: 1, date: '%m月%j日' }
        ]
      });
      
      // 日レベル
      act(() => {
        result.current.setLevel('day');
      });
      expect(result.current.config).toMatchObject({
        scale_unit: 'day',
        date_scale: '%j',
        subscales: [
          { unit: 'month', step: 1, date: '%Y年%n月' }
        ]
      });
      
      // 週レベル
      act(() => {
        result.current.setLevel('week');
      });
      expect(result.current.config).toMatchObject({
        scale_unit: 'week',
        date_scale: '第%W週',
        subscales: [
          { unit: 'month', step: 1, date: '%Y年%n月' }
        ]
      });
      
      // 月レベル
      act(() => {
        result.current.setLevel('month');
      });
      expect(result.current.config).toMatchObject({
        scale_unit: 'month',
        date_scale: '%Y年%n月'
      });
      
      // 四半期レベル
      act(() => {
        result.current.setLevel('quarter');
      });
      expect(result.current.config).toMatchObject({
        scale_unit: 'quarter',
        date_scale: 'Q%q',
        subscales: [
          { unit: 'year', step: 1, date: '%Y年' }
        ]
      });
      
      // 年レベル
      act(() => {
        result.current.setLevel('year');
      });
      expect(result.current.config).toMatchObject({
        scale_unit: 'year',
        date_scale: '%Y年'
      });
    });

    it('ズームレベル変更時にCookieに保存する', () => {
      const { result } = renderHook(() => useZoomConfigDHMLX());
      
      act(() => {
        result.current.setLevel('week');
      });
      
      expect(cookies.setCookie).toHaveBeenCalledWith('zoomLevel', 'week', 30);
    });

    it('無効なズームレベルはデフォルト（day）にフォールバックする', () => {
      const { result } = renderHook(() => useZoomConfigDHMLX());
      
      act(() => {
        result.current.setLevel('invalid_level');
      });
      
      expect(result.current.level).toBe('day');
    });

    it('各ズームレベルの最小カラム幅を正しく設定する', () => {
      const { result } = renderHook(() => useZoomConfigDHMLX());
      
      // 各レベルの最小カラム幅を確認
      const expectedWidths = {
        hour: 50,
        day: 50,
        week: 100,
        month: 120,
        quarter: 150,
        year: 200
      };
      
      Object.entries(expectedWidths).forEach(([level, width]) => {
        act(() => {
          result.current.setLevel(level);
        });
        expect(result.current.config.min_column_width).toBe(width);
      });
    });
  });
});