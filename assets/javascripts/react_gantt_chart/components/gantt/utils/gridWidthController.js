/**
 * ガントグリッド幅制御ユーティリティ
 * 指定された2つのレイアウトセルの幅を同時に制御
 */

class GridWidthController {
  constructor(gantt) {
    this.gantt = gantt;
    this.currentWidth = 500; // デフォルト幅
    this.observers = new Set(); // 幅変更通知のオブザーバー
    
    this.init();
  }

  init() {
    console.log('GridWidthController: 初期化開始');
    
    // 保存された幅を復元
    this.loadSavedWidth();
    console.log('GridWidthController: 保存された幅を復元完了 -', this.currentWidth);
    
    // ガントチャート準備完了時に幅を適用
    this.gantt.attachEvent("onGanttReady", () => {
      console.log('GridWidthController: onGanttReady - 幅を適用');
      this.applyGridWidth(this.currentWidth);
    });

    // データ変更時に幅を再適用
    this.gantt.attachEvent("onParse", () => {
      console.log('GridWidthController: onParse - 幅を再適用');
      setTimeout(() => this.applyGridWidth(this.currentWidth), 100);
    });
    
    console.log('GridWidthController: 初期化完了');
  }

  /**
   * 対象のレイアウトセルを取得
   */
  getTargetElements() {
    const elements = [];
    
    // 1つ目: 外側のレイアウトセル（data-cell-idがcで始まる）
    const outerCell = document.querySelector('.gantt_layout_cell.gantt_layout.gantt_layout_y.gantt_layout_cell_border_right[data-cell-id^="c"]');
    if (outerCell) {
      elements.push({ element: outerCell, type: 'outer' });
    }
    
    // 2つ目: 内側のグリッドセル（grid_cellクラスを持つ）
    const innerCell = document.querySelector('.gantt_layout_cell.grid_cell.gantt_layout_cell_border_transparent.gantt_layout_outer_scroll');
    if (innerCell) {
      elements.push({ element: innerCell, type: 'inner' });
    }

    return elements;
  }

  /**
   * グリッド幅を適用
   */
  applyGridWidth(width) {
    if (!this.gantt || width < 250 || width > 1000) {
      console.warn('GridWidthController: 無効な幅:', width);
      return;
    }

    this.currentWidth = width;

    // 対象要素に幅を適用
    const elements = this.getTargetElements();
    console.log(`GridWidthController: ${elements.length}個の要素に幅 ${width}px を適用`);

    // 各要素に適切な幅を適用
    elements.forEach((elementObj) => {
      const { element, type } = elementObj;
      let targetWidth;
      
      if (type === 'outer') {
        // 外側の要素は指定された幅
        targetWidth = width;
      } else if (type === 'inner') {
        // 内側の要素は1px小さく
        targetWidth = width - 1;
      } else {
        targetWidth = width;
      }
      
      element.style.width = `${targetWidth}px`;
      element.style.minWidth = `${targetWidth}px`;
      element.style.maxWidth = `${targetWidth}px`;
      
      console.log(`要素 (${type}): ${targetWidth}px 適用 - ${element.className.substring(0, 50)}...`);
    });

    // ガントチャートの設定も更新
    this.gantt.config.grid_width = width;
    
    // ガントチャートを再描画
    this.gantt.render();

    // オブザーバーに通知
    this.notifyObservers(width);
    
    // 設定を保存
    this.saveWidth(width);

    console.log(`GridWidthController: グリッド幅を ${width}px に変更完了 (inner要素は${width-1}px)`);
  }

  /**
   * 現在の幅を取得
   */
  getCurrentWidth() {
    return this.currentWidth;
  }

  /**
   * 幅変更のオブザーバーを追加
   */
  addObserver(callback) {
    this.observers.add(callback);
  }

  /**
   * 幅変更のオブザーバーを削除
   */
  removeObserver(callback) {
    this.observers.delete(callback);
  }

  /**
   * オブザーバーに通知
   */
  notifyObservers(width) {
    this.observers.forEach(callback => {
      try {
        callback(width);
      } catch (error) {
        console.error('GridWidthController observer error:', error);
      }
    });
  }

  /**
   * 保存された幅を読み込み
   */
  loadSavedWidth() {
    try {
      const savedWidth = localStorage.getItem('gantt_grid_width');
      if (savedWidth) {
        const width = parseInt(savedWidth);
        if (width >= 250 && width <= 1000) {
          this.currentWidth = width;
          console.log(`GridWidthController: 保存された幅 ${width}px を復元`);
        }
      }
    } catch (error) {
      console.warn('GridWidthController: 幅の読み込みに失敗:', error);
    }
  }

  /**
   * 幅を保存
   */
  saveWidth(width) {
    try {
      localStorage.setItem('gantt_grid_width', width.toString());
    } catch (error) {
      console.warn('GridWidthController: 幅の保存に失敗:', error);
    }
  }

  /**
   * デフォルト幅に戻す
   */
  resetToDefault() {
    this.applyGridWidth(500);
  }

  /**
   * プリセット幅を適用
   */
  applyPreset(presetName) {
    const presets = {
      narrow: 300,
      standard: 500,
      wide: 700,
      max: 900
    };

    const width = presets[presetName];
    if (width) {
      this.applyGridWidth(width);
    } else {
      console.warn('GridWidthController: 不明なプリセット:', presetName);
    }
  }

  /**
   * 指定された値だけ幅を増減
   */
  adjustWidth(delta) {
    const newWidth = Math.max(250, Math.min(1000, this.currentWidth + delta));
    this.applyGridWidth(newWidth);
  }

  /**
   * 破棄
   */
  destroy() {
    this.observers.clear();
  }
}

// エクスポート
export default GridWidthController;

/**
 * ガントチャートにグリッド幅制御機能を設定
 */
export const setupGridWidthController = (gantt) => {
  console.log('setupGridWidthController: 呼び出し開始 - gantt:', !!gantt);
  
  // 既存のインスタンスがあれば削除
  if (gantt._gridWidthController) {
    console.log('setupGridWidthController: 既存のコントローラーを削除');
    gantt._gridWidthController.destroy();
  }
  
  // 新しいインスタンスを作成
  console.log('setupGridWidthController: 新しいコントローラーを作成');
  gantt._gridWidthController = new GridWidthController(gantt);
  console.log('setupGridWidthController: コントローラー作成完了 - _gridWidthController:', !!gantt._gridWidthController);
  
  return gantt._gridWidthController;
};