import React, { createContext, useContext, useState, useEffect, useMemo } from 'react';

/**
 * デフォルトテーマ定義
 */
const defaultTheme = {
  colors: {
    // プライマリカラー
    primary: {
      50: '#eff6ff',
      100: '#dbeafe',
      200: '#bfdbfe',
      300: '#93c5fd',
      400: '#60a5fa',
      500: '#3b82f6',
      600: '#2563eb',
      700: '#1d4ed8',
      800: '#1e40af',
      900: '#1e3a8a'
    },

    // 状態カラー
    success: {
      50: '#ecfdf5',
      100: '#d1fae5',
      200: '#a7f3d0',
      300: '#6ee7b7',
      400: '#34d399',
      500: '#10b981',
      600: '#059669',
      700: '#047857',
      800: '#065f46',
      900: '#064e3b'
    },

    warning: {
      50: '#fffbeb',
      100: '#fef3c7',
      200: '#fde68a',
      300: '#fcd34d',
      400: '#fbbf24',
      500: '#f59e0b',
      600: '#d97706',
      700: '#b45309',
      800: '#92400e',
      900: '#78350f'
    },

    danger: {
      50: '#fef2f2',
      100: '#fee2e2',
      200: '#fecaca',
      300: '#fca5a5',
      400: '#f87171',
      500: '#ef4444',
      600: '#dc2626',
      700: '#b91c1c',
      800: '#991b1b',
      900: '#7f1d1d'
    },

    // グレースケール
    gray: {
      50: '#f9fafb',
      100: '#f3f4f6',
      200: '#e5e7eb',
      300: '#d1d5db',
      400: '#9ca3af',
      500: '#6b7280',
      600: '#4b5563',
      700: '#374151',
      800: '#1f2937',
      900: '#111827'
    }
  },

  // フォント設定
  fonts: {
    sans: ['-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', 'sans-serif'].join(', '),
    mono: ['SFMono-Regular', 'Menlo', 'Monaco', 'Consolas', 'Liberation Mono', 'Courier New', 'monospace'].join(', ')
  },

  // フォントサイズ
  fontSizes: {
    xs: '0.75rem',
    sm: '0.875rem',
    base: '1rem',
    lg: '1.125rem',
    xl: '1.25rem',
    '2xl': '1.5rem',
    '3xl': '1.875rem',
    '4xl': '2.25rem'
  },

  // フォントウェイト
  fontWeights: {
    normal: '400',
    medium: '500',
    semibold: '600',
    bold: '700'
  },

  // ライン高
  lineHeights: {
    tight: '1.25',
    normal: '1.5',
    relaxed: '1.625'
  },

  // スペーシング
  spacing: {
    0: '0',
    1: '0.25rem',
    2: '0.5rem',
    3: '0.75rem',
    4: '1rem',
    5: '1.25rem',
    6: '1.5rem',
    8: '2rem',
    10: '2.5rem',
    12: '3rem',
    16: '4rem',
    20: '5rem',
    24: '6rem'
  },

  // ボーダー半径
  borderRadius: {
    none: '0',
    sm: '0.125rem',
    base: '0.25rem',
    md: '0.375rem',
    lg: '0.5rem',
    xl: '0.75rem',
    '2xl': '1rem',
    full: '9999px'
  },

  // ボーダー幅
  borderWidth: {
    0: '0',
    1: '1px',
    2: '2px',
    4: '4px',
    8: '8px'
  },

  // シャドウ
  shadows: {
    sm: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
    base: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)',
    md: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
    lg: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
    xl: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)'
  },

  // ブレークポイント
  breakpoints: {
    sm: '640px',
    md: '768px',
    lg: '1024px',
    xl: '1280px',
    '2xl': '1536px'
  },

  // z-index
  zIndex: {
    auto: 'auto',
    0: '0',
    10: '10',
    20: '20',
    30: '30',
    40: '40',
    50: '50',
    dropdown: '1000',
    sticky: '1020',
    fixed: '1030',
    overlay: '1040',
    modal: '1050',
    popover: '1060',
    tooltip: '1070'
  }
};

/**
 * ダークテーマ設定
 */
const darkTheme = {
  ...defaultTheme,
  colors: {
    ...defaultTheme.colors,
    // ダークモード用のカラー調整
    primary: {
      ...defaultTheme.colors.primary,
      500: '#60a5fa',
      600: '#3b82f6'
    },
    gray: {
      50: '#1f2937',
      100: '#374151',
      200: '#4b5563',
      300: '#6b7280',
      400: '#9ca3af',
      500: '#d1d5db',
      600: '#e5e7eb',
      700: '#f3f4f6',
      800: '#f9fafb',
      900: '#ffffff'
    }
  }
};

/**
 * テーマコンテキスト
 */
const ThemeContext = createContext({
  theme: defaultTheme,
  mode: 'light',
  setMode: () => {},
  toggleMode: () => {},
  customTheme: null,
  setCustomTheme: () => {}
});

/**
 * ThemeProvider Component
 * デザインシステムの統一テーマを提供するProvider
 *
 * @param {Object} props
 * @param {React.ReactNode} props.children - 子コンポーネント
 * @param {'light'|'dark'|'system'} props.defaultMode - デフォルトモード
 * @param {Object} props.customTheme - カスタムテーマオブジェクト
 * @param {boolean} props.enableSystemTheme - システムテーマ検出有効
 * @param {string} props.storageKey - localStorage保存キー
 */
const ThemeProvider = ({
  children,
  defaultMode = 'system',
  customTheme = null,
  enableSystemTheme = true,
  storageKey = 'kanban-theme-mode'
}) => {
  // システムのダークモード検出
  const getSystemMode = () => {
    if (!enableSystemTheme || typeof window === 'undefined') {
      return 'light';
    }
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  };

  // 保存済みモードの取得
  const getSavedMode = () => {
    if (typeof window === 'undefined') {
      return defaultMode;
    }
    try {
      return localStorage.getItem(storageKey) || defaultMode;
    } catch {
      return defaultMode;
    }
  };

  // 実際のモードを計算
  const calculateActualMode = (mode) => {
    if (mode === 'system') {
      return getSystemMode();
    }
    return mode;
  };

  const [mode, setModeState] = useState(getSavedMode);
  const [systemMode, setSystemMode] = useState(getSystemMode);
  const [customThemeState, setCustomThemeState] = useState(customTheme);

  // システムテーマ変更の監視
  useEffect(() => {
    if (!enableSystemTheme || typeof window === 'undefined') {
      return;
    }

    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    const handleChange = (e) => {
      setSystemMode(e.matches ? 'dark' : 'light');
    };

    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, [enableSystemTheme]);

  // モード保存
  const setMode = (newMode) => {
    setModeState(newMode);
    if (typeof window !== 'undefined') {
      try {
        localStorage.setItem(storageKey, newMode);
      } catch {
        // localStorage使用不可時は無視
      }
    }
  };

  // モード切り替え
  const toggleMode = () => {
    const actualMode = calculateActualMode(mode);
    setMode(actualMode === 'dark' ? 'light' : 'dark');
  };

  // カスタムテーマ設定
  const setCustomTheme = (newTheme) => {
    setCustomThemeState(newTheme);
  };

  // 最終的なテーマオブジェクトを生成
  const finalTheme = useMemo(() => {
    const actualMode = calculateActualMode(mode);
    const baseTheme = actualMode === 'dark' ? darkTheme : defaultTheme;

    // カスタムテーマがある場合は深いマージを行う
    if (customThemeState) {
      return mergeThemes(baseTheme, customThemeState);
    }

    return baseTheme;
  }, [mode, systemMode, customThemeState]);

  // CSS変数をドキュメントに適用
  useEffect(() => {
    if (typeof document === 'undefined') {
      return;
    }

    const root = document.documentElement;
    const actualMode = calculateActualMode(mode);

    // テーマモードのクラスを設定
    root.classList.remove('theme-light', 'theme-dark');
    root.classList.add(`theme-${actualMode}`);

    // CSS変数を設定
    const setCSSVars = (obj, prefix = '--theme') => {
      Object.entries(obj).forEach(([key, value]) => {
        if (typeof value === 'object' && value !== null) {
          setCSSVars(value, `${prefix}-${key}`);
        } else {
          root.style.setProperty(`${prefix}-${key}`, value);
        }
      });
    };

    setCSSVars(finalTheme);
  }, [finalTheme, mode, systemMode]);

  const value = {
    theme: finalTheme,
    mode: calculateActualMode(mode),
    rawMode: mode,
    setMode,
    toggleMode,
    customTheme: customThemeState,
    setCustomTheme
  };

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  );
};

/**
 * テーマフック
 */
const useTheme = () => {
  const context = useContext(ThemeContext);
  if (context === undefined) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
};

/**
 * テーママージユーティリティ
 */
const mergeThemes = (base, custom) => {
  const merged = { ...base };

  Object.entries(custom).forEach(([key, value]) => {
    if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
      merged[key] = mergeThemes(merged[key] || {}, value);
    } else {
      merged[key] = value;
    }
  });

  return merged;
};

/**
 * テーマアクセサヘルパー
 */
const useThemeValue = (path, fallback = undefined) => {
  const { theme } = useTheme();

  return useMemo(() => {
    const keys = path.split('.');
    let value = theme;

    for (const key of keys) {
      if (value && typeof value === 'object' && key in value) {
        value = value[key];
      } else {
        return fallback;
      }
    }

    return value;
  }, [theme, path, fallback]);
};

/**
 * レスポンシブヘルパー
 */
const useBreakpoint = () => {
  const { theme } = useTheme();
  const [currentBreakpoint, setCurrentBreakpoint] = useState('sm');

  useEffect(() => {
    if (typeof window === 'undefined') {
      return;
    }

    const updateBreakpoint = () => {
      const width = window.innerWidth;
      const breakpoints = Object.entries(theme.breakpoints)
        .map(([key, value]) => [key, parseInt(value)])
        .sort((a, b) => a[1] - b[1]);

      for (let i = breakpoints.length - 1; i >= 0; i--) {
        if (width >= breakpoints[i][1]) {
          setCurrentBreakpoint(breakpoints[i][0]);
          return;
        }
      }
      setCurrentBreakpoint('sm');
    };

    updateBreakpoint();
    window.addEventListener('resize', updateBreakpoint);
    return () => window.removeEventListener('resize', updateBreakpoint);
  }, [theme.breakpoints]);

  return {
    current: currentBreakpoint,
    is: (breakpoint) => currentBreakpoint === breakpoint,
    isAbove: (breakpoint) => {
      const breakpoints = Object.keys(theme.breakpoints);
      const currentIndex = breakpoints.indexOf(currentBreakpoint);
      const targetIndex = breakpoints.indexOf(breakpoint);
      return currentIndex > targetIndex;
    },
    isBelow: (breakpoint) => {
      const breakpoints = Object.keys(theme.breakpoints);
      const currentIndex = breakpoints.indexOf(currentBreakpoint);
      const targetIndex = breakpoints.indexOf(breakpoint);
      return currentIndex < targetIndex;
    }
  };
};

export default ThemeProvider;
export { useTheme, useThemeValue, useBreakpoint, defaultTheme, darkTheme };