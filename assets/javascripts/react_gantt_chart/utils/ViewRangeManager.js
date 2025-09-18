/**
 * ViewRangeManager - 統一された期間管理システム
 * 
 * React状態・Cookie・DHTMLX Ganttの期間を同期管理
 * 期間変更機能の根本問題を解決
 */

import { GanttSettings } from './cookieUtils';

export class ViewRangeManager {
  constructor() {
    this.listeners = new Set();
    this.zoomListeners = new Set();
    this.currentRange = null;
    this.currentZoom = null;
    this.ganttInstance = null;
    
    // 初期化時にCookieから読み込み
    this.loadFromCookie();
  }

  /**
   * Ganttインスタンスを登録
   */
  setGanttInstance(ganttInstance) {
    this.ganttInstance = ganttInstance;
    console.log('ViewRangeManager: Ganttインスタンス登録');
  }

  /**
   * 期間変更リスナーを追加
   */
  addListener(callback) {
    this.listeners.add(callback);
    return () => this.listeners.delete(callback);
  }

  /**
   * ズーム変更リスナーを追加
   */
  addZoomListener(callback) {
    this.zoomListeners.add(callback);
    return () => this.zoomListeners.delete(callback);
  }

  /**
   * 現在の期間を取得
   */
  getCurrentRange() {
    return this.currentRange ? { ...this.currentRange } : null;
  }

  /**
   * 現在のズームレベルを取得
   */
  getCurrentZoom() {
    return this.currentZoom;
  }

  /**
   * 期間を設定（全状態を同期）
   */
  setRange(startDate, endDate) {
    console.log('ViewRangeManager: 期間設定', { startDate, endDate });
    
    // 入力値検証
    if (!startDate) {
      startDate = this.calculateDefaultStartDate();
    }
    
    const newRange = {
      start: startDate,
      end: endDate || null,
      timestamp: Date.now()
    };
    
    // 変更がない場合は処理しない
    if (this.isRangeEqual(this.currentRange, newRange)) {
      console.log('ViewRangeManager: 期間変更なし、スキップ');
      return;
    }
    
    this.currentRange = newRange;
    
    // 1. Cookie保存
    this.saveToCookie();
    
    // 2. DHTMLX Gantt更新
    this.updateGanttRange();
    
    // 3. リスナーに通知
    this.notifyListeners();
  }

  /**
   * ズームレベルを設定
   */
  setZoom(zoomLevel) {
    console.log('ViewRangeManager: ズームレベル設定', zoomLevel);
    
    if (this.currentZoom === zoomLevel) {
      console.log('ViewRangeManager: ズームレベル変更なし、スキップ');
      return;
    }
    
    this.currentZoom = zoomLevel;
    
    // Cookie保存
    GanttSettings.setZoomLevel(zoomLevel);
    
    // リスナーに通知
    this.notifyZoomListeners();
  }

  /**
   * Cookieから期間読み込み
   */
  loadFromCookie() {
    try {
      const savedRange = GanttSettings.getViewRange();
      const savedZoom = GanttSettings.getZoomLevel();
      console.log('ViewRangeManager: Cookie読み込み', { range: savedRange, zoom: savedZoom });
      
      // 期間の読み込み
      if (savedRange && savedRange.start) {
        this.currentRange = {
          start: savedRange.start,
          end: savedRange.end || null,
          timestamp: Date.now()
        };
      } else {
        // デフォルト期間設定
        const defaultStart = this.calculateDefaultStartDate();
        const defaultEnd = this.calculateDefaultEndDate();
        this.currentRange = {
          start: defaultStart,
          end: defaultEnd,
          timestamp: Date.now()
        };
        this.saveToCookie(); // デフォルト値を保存
      }
      
      // ズームレベルの読み込み
      this.currentZoom = savedZoom;
    } catch (error) {
      console.error('ViewRangeManager: Cookie読み込みエラー', error);
      this.setDefaultRange();
      this.currentZoom = 'month';
    }
  }

  /**
   * Cookieに期間保存
   */
  saveToCookie() {
    try {
      GanttSettings.setViewRange(this.currentRange.start, this.currentRange.end);
      console.log('ViewRangeManager: Cookie保存完了', this.currentRange);
    } catch (error) {
      console.error('ViewRangeManager: Cookie保存エラー', error);
    }
  }

  /**
   * DHTMLX Gantt期間更新
   */
  updateGanttRange() {
    if (!this.ganttInstance || !this.currentRange) {
      console.log('ViewRangeManager: Gantt更新スキップ（インスタンスまたは期間なし）');
      return;
    }
    
    try {
      const { start, end } = this.currentRange;
      
      // DHTMLX Ganttの期間設定
      if (start) {
        const startDate = new Date(start);
        const endDate = end ? new Date(end) : this.calculateAutoEndDate(startDate);
        
        // Ganttの表示期間を設定
        this.ganttInstance.config.start_date = startDate;
        this.ganttInstance.config.end_date = endDate;
        
        // 再描画
        this.ganttInstance.render();
        
        console.log('ViewRangeManager: Gantt期間更新完了', { start: startDate, end: endDate });
      }
    } catch (error) {
      console.error('ViewRangeManager: Gantt期間更新エラー', error);
    }
  }

  /**
   * リスナーに変更通知
   */
  notifyListeners() {
    const range = this.getCurrentRange();
    this.listeners.forEach(callback => {
      try {
        callback(range);
      } catch (error) {
        console.error('ViewRangeManager: リスナー通知エラー', error);
      }
    });
  }

  /**
   * ズームリスナーに変更通知
   */
  notifyZoomListeners() {
    const zoom = this.getCurrentZoom();
    this.zoomListeners.forEach(callback => {
      try {
        callback(zoom);
      } catch (error) {
        console.error('ViewRangeManager: ズームリスナー通知エラー', error);
      }
    });
  }

  /**
   * 期間の同等性チェック
   */
  isRangeEqual(range1, range2) {
    if (!range1 && !range2) return true;
    if (!range1 || !range2) return false;
    return range1.start === range2.start && range1.end === range2.end;
  }

  /**
   * デフォルト開始日計算
   */
  calculateDefaultStartDate() {
    const today = new Date();
    const firstDay = new Date(today.getFullYear(), today.getMonth(), 1);
    return firstDay.toISOString().split('T')[0];
  }

  /**
   * デフォルト終了日計算
   */
  calculateDefaultEndDate() {
    const today = new Date();
    const lastDay = new Date(today.getFullYear(), today.getMonth() + 3, 0); // 3ヶ月後
    return lastDay.toISOString().split('T')[0];
  }

  /**
   * 自動終了日計算（開始日から）
   */
  calculateAutoEndDate(startDate) {
    const end = new Date(startDate);
    end.setMonth(end.getMonth() + 3); // 3ヶ月後
    return end;
  }

  /**
   * デフォルト期間設定
   */
  setDefaultRange() {
    const start = this.calculateDefaultStartDate();
    const end = this.calculateDefaultEndDate();
    this.setRange(start, end);
  }

  /**
   * 破棄処理
   */
  destroy() {
    this.listeners.clear();
    this.zoomListeners.clear();
    this.ganttInstance = null;
    this.currentRange = null;
    this.currentZoom = null;
  }
}

// シングルトンインスタンス
export const viewRangeManager = new ViewRangeManager();