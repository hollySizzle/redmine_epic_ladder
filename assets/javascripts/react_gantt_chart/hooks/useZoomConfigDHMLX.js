import { useState, useEffect } from 'react';
import { getCookie, setCookie } from '../utils/cookies';

/**
 * DHTMLX Gantt用ズーム設定カスタムフック
 * @returns {Object} ズーム設定オブジェクト
 */
export const useZoomConfigDHMLX = () => {
  const [level, setLevel] = useState('day');

  // ズーム設定をCookieから復元
  useEffect(() => {
    const savedLevel = getCookie('gantt_zoom_level');
    if (savedLevel && isValidZoomLevel(savedLevel)) {
      setLevel(savedLevel);
    }
  }, []);

  // ズーム設定をCookieに保存
  const setZoomLevel = (newLevel) => {
    if (isValidZoomLevel(newLevel)) {
      setLevel(newLevel);
      setCookie('gantt_zoom_level', newLevel, 365);
    }
  };

  // ズームレベルの妥当性チェック
  const isValidZoomLevel = (level) => {
    const validLevels = ['year', 'quarter', 'month', 'week', 'day'];
    return validLevels.includes(level);
  };

  // DHTMLX Gantt設定を生成
  const generateGanttConfig = () => {
    const configs = {
      year: {
        scales: [
          {unit: 'year', step: 1, format: '%Y年'},
          {unit: 'month', step: 3, format: '%M'}
        ],
        scale_height: 50,
        min_column_width: 100
      },
      quarter: {
        scales: [
          {unit: 'year', step: 1, format: '%Y年'},
          {unit: 'quarter', step: 1, format: 'Q%q'},
          {unit: 'month', step: 1, format: '%M'}
        ],
        scale_height: 50,
        min_column_width: 80
      },
      month: {
        scales: [
          {unit: 'year', step: 1, format: '%Y年'},
          {unit: 'month', step: 1, format: '%m月'},
          {unit: 'week', step: 1, format: '%d日'}
        ],
        scale_height: 50,
        min_column_width: 70
      },
      week: {
        scales: [
          {unit: 'month', step: 1, format: '%Y年%m月'},
          {unit: 'week', step: 1, format: '%W週'},
          {unit: 'day', step: 1, format: '%d'}
        ],
        scale_height: 50,
        min_column_width: 60
      },
      day: {
        scales: [
          {unit: 'month', step: 1, format: '%Y年%m月'},
          {unit: 'day', step: 1, format: '%d日 (%D)'}
        ],
        scale_height: 50,
        min_column_width: 40
      }
    };

    return configs[level] || configs.day;
  };

  // ズームレベル情報を取得
  const getZoomLevelInfo = () => {
    const levelInfo = {
      year: {
        name: '年',
        description: '年単位での表示',
        unit: 'year',
        step: 1
      },
      quarter: {
        name: '四半期',
        description: '四半期単位での表示',
        unit: 'quarter',
        step: 1
      },
      month: {
        name: '月',
        description: '月単位での表示',
        unit: 'month',
        step: 1
      },
      week: {
        name: '週',
        description: '週単位での表示',
        unit: 'week',
        step: 1
      },
      day: {
        name: '日',
        description: '日単位での表示',
        unit: 'day',
        step: 1
      },
    };

    return levelInfo[level] || levelInfo.day;
  };

  // 次のズームレベルを取得
  const getNextZoomLevel = () => {
    const levels = ['year', 'quarter', 'month', 'week', 'day'];
    const currentIndex = levels.indexOf(level);
    const nextIndex = (currentIndex + 1) % levels.length;
    return levels[nextIndex];
  };

  // 前のズームレベルを取得
  const getPreviousZoomLevel = () => {
    const levels = ['year', 'quarter', 'month', 'week', 'day'];
    const currentIndex = levels.indexOf(level);
    const previousIndex = (currentIndex - 1 + levels.length) % levels.length;
    return levels[previousIndex];
  };

  // ズームイン
  const zoomIn = () => {
    const levels = ['year', 'quarter', 'month', 'week', 'day'];
    const currentIndex = levels.indexOf(level);
    if (currentIndex < levels.length - 1) {
      setZoomLevel(levels[currentIndex + 1]);
    }
  };

  // ズームアウト
  const zoomOut = () => {
    const levels = ['year', 'quarter', 'month', 'week', 'day'];
    const currentIndex = levels.indexOf(level);
    if (currentIndex > 0) {
      setZoomLevel(levels[currentIndex - 1]);
    }
  };

  // ズームレベルのオプション一覧
  const getZoomOptions = () => {
    return [
      { value: 'year', label: '年表示' },
      { value: 'quarter', label: '四半期表示' },
      { value: 'month', label: '月表示' },
      { value: 'week', label: '週表示' },
      { value: 'day', label: '日表示' }
    ];
  };

  // スケールの日付フォーマット設定
  const getDateFormats = () => {
    const formats = {
      year: {
        scale: '%Y年',
        tooltip: '%Y年%m月%d日'
      },
      quarter: {
        scale: 'Q%q',
        tooltip: '%Y年%m月%d日'
      },
      month: {
        scale: '%m月',
        tooltip: '%Y年%m月%d日'
      },
      week: {
        scale: '%W週',
        tooltip: '%Y年%m月%d日'
      },
      day: {
        scale: '%d日',
        tooltip: '%Y年%m月%d日'
      }
    };

    return formats[level] || formats.day;
  };

  // ズームレベルに応じた表示期間の算出
  const getVisiblePeriod = () => {
    const periods = {
      year: { amount: 5, unit: 'year' },
      quarter: { amount: 2, unit: 'year' },
      month: { amount: 1, unit: 'year' },
      week: { amount: 6, unit: 'month' },
      day: { amount: 2, unit: 'month' }
    };

    return periods[level] || periods.day;
  };

  // レスポンシブ対応のためのカラム幅計算
  const getColumnWidth = () => {
    const widths = {
      year: 120,
      quarter: 80,
      month: 70,
      week: 60,
      day: 40
    };

    return widths[level] || 40;
  };

  return {
    level,
    setLevel: setZoomLevel,
    config: generateGanttConfig(),
    levelInfo: getZoomLevelInfo(),
    nextLevel: getNextZoomLevel(),
    previousLevel: getPreviousZoomLevel(),
    zoomIn,
    zoomOut,
    options: getZoomOptions(),
    dateFormats: getDateFormats(),
    visiblePeriod: getVisiblePeriod(),
    columnWidth: getColumnWidth()
  };
};