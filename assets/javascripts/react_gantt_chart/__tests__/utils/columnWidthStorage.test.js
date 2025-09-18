import {
  saveColumnWidths,
  loadColumnWidths,
  clearColumnWidths
} from '../../utils/columnWidthStorage';

describe('columnWidthStorage', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  describe('F004: カラム幅設定の永続化', () => {
    it('カラム幅設定をローカルストレージに保存する', () => {
      const widths = {
        text: 250,
        status_name: 120,
        assigned_to_name: 150
      };
      const projectId = 'test-project';
      
      saveColumnWidths(projectId, widths);
      
      const savedData = localStorage.getItem(`gantt_column_widths_${projectId}`);
      expect(JSON.parse(savedData)).toEqual(widths);
    });

    it('カラム幅設定をローカルストレージから読み込む', () => {
      const widths = {
        text: 300,
        tracker_name: 80,
        progress: 70
      };
      const projectId = 'test-project';
      
      localStorage.setItem(`gantt_column_widths_${projectId}`, JSON.stringify(widths));
      
      const loadedWidths = loadColumnWidths(projectId);
      expect(loadedWidths).toEqual(widths);
    });

    it('保存された設定がない場合は空オブジェクトを返す', () => {
      const projectId = 'test-project';
      
      const loadedWidths = loadColumnWidths(projectId);
      expect(loadedWidths).toEqual({});
    });

    it('カラム幅設定をクリアする', () => {
      const projectId = 'test-project';
      const widths = { text: 250 };
      
      // 設定を保存
      saveColumnWidths(projectId, widths);
      expect(localStorage.getItem(`gantt_column_widths_${projectId}`)).toBeTruthy();
      
      // 設定をクリア
      clearColumnWidths(projectId);
      expect(localStorage.getItem(`gantt_column_widths_${projectId}`)).toBeNull();
    });

    it('プロジェクトごとに分離して保存する', () => {
      const projectA = 'project-a';
      const projectB = 'project-b';
      const widthsA = { text: 200 };
      const widthsB = { text: 300 };
      
      saveColumnWidths(projectA, widthsA);
      saveColumnWidths(projectB, widthsB);
      
      expect(loadColumnWidths(projectA)).toEqual(widthsA);
      expect(loadColumnWidths(projectB)).toEqual(widthsB);
    });

    it('無効なJSONデータが保存されている場合は空オブジェクトを返す', () => {
      const projectId = 'test-project';
      
      // 無効なJSONデータを保存
      localStorage.setItem(`gantt_column_widths_${projectId}`, 'invalid json');
      
      const loadedWidths = loadColumnWidths(projectId);
      expect(loadedWidths).toEqual({});
    });

    it('カラム幅の最小値と最大値を制限する', () => {
      const projectId = 'test-project';
      
      // 最小値を下回る値を保存
      const invalidWidths = {
        text: 10, // 最小値以下
        status_name: 1000 // 最大値以上
      };
      
      saveColumnWidths(projectId, invalidWidths);
      
      // 保存された値は制限される
      const savedData = JSON.parse(localStorage.getItem(`gantt_column_widths_${projectId}`));
      expect(savedData.text).toBeGreaterThanOrEqual(50); // 最小値
      expect(savedData.status_name).toBeLessThanOrEqual(500); // 最大値
    });
  });
});