import {
  saveColumnSettings,
  loadColumnSettings,
  getDefaultColumns,
  clearColumnSettings
} from '../../utils/columnStorage';

describe('columnStorage', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  describe('F004: カラム設定の永続化', () => {
    it('カラム設定をローカルストレージに保存する', () => {
      const columns = ['id', 'text', 'status_name'];
      const projectId = 'test-project';
      
      saveColumnSettings(projectId, columns);
      
      const savedData = localStorage.getItem(`gantt_columns_${projectId}`);
      expect(JSON.parse(savedData)).toEqual(columns);
    });

    it('カラム設定をローカルストレージから読み込む', () => {
      const columns = ['id', 'text', 'tracker_name'];
      const projectId = 'test-project';
      
      localStorage.setItem(`gantt_columns_${projectId}`, JSON.stringify(columns));
      
      const loadedColumns = loadColumnSettings(projectId);
      expect(loadedColumns).toEqual(columns);
    });

    it('保存された設定がない場合はデフォルトを返す', () => {
      const projectId = 'test-project';
      
      const loadedColumns = loadColumnSettings(projectId);
      const defaultColumns = getDefaultColumns();
      
      expect(loadedColumns).toEqual(defaultColumns);
    });

    it('デフォルトカラム設定を正しく返す', () => {
      const defaultColumns = getDefaultColumns();
      
      expect(defaultColumns).toEqual([
        'text',
        'status_name',
        'assigned_to_name',
        'start_date',
        'duration',
        'progress'
      ]);
    });

    it('カラム設定をクリアする', () => {
      const projectId = 'test-project';
      
      // 設定を保存
      saveColumnSettings(projectId, ['id', 'text']);
      expect(localStorage.getItem(`gantt_columns_${projectId}`)).toBeTruthy();
      
      // 設定をクリア
      clearColumnSettings(projectId);
      expect(localStorage.getItem(`gantt_columns_${projectId}`)).toBeNull();
    });

    it('プロジェクトごとに分離して保存する', () => {
      const projectA = 'project-a';
      const projectB = 'project-b';
      const columnsA = ['id', 'text'];
      const columnsB = ['text', 'status_name'];
      
      saveColumnSettings(projectA, columnsA);
      saveColumnSettings(projectB, columnsB);
      
      expect(loadColumnSettings(projectA)).toEqual(columnsA);
      expect(loadColumnSettings(projectB)).toEqual(columnsB);
    });

    it('無効なJSONデータが保存されている場合はデフォルトを返す', () => {
      const projectId = 'test-project';
      
      // 無効なJSONデータを保存
      localStorage.setItem(`gantt_columns_${projectId}`, 'invalid json');
      
      const loadedColumns = loadColumnSettings(projectId);
      expect(loadedColumns).toEqual(getDefaultColumns());
    });
  });
});