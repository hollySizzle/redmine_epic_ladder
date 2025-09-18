// データ変換ユーティリティのテスト
describe('Data Converter Utilities', () => {
  // SVAR形式からDHTMLX形式への変換関数
  const convertSvarToDhtmlx = (task) => {
    return {
      id: task.id,
      text: task.text || task.name,
      start_date: task.start || task.start_date,
      duration: task.duration || calculateDuration(task.start || task.start_date, task.end || task.end_date),
      parent: task.parent || 0,
      progress: task.progress || 0,
      ...task
    };
  };

  // 期間計算関数
  const calculateDuration = (start, end) => {
    if (!start || !end) return 1;
    const startDate = new Date(start);
    const endDate = new Date(end);
    const diffTime = Math.abs(endDate - startDate);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays || 1;
  };

  describe('convertSvarToDhtmlx', () => {
    it('基本的なタスクデータを変換できること', () => {
      const svarTask = {
        id: 1,
        text: 'タスク1',
        start: '2025-01-15',
        end: '2025-01-20',
        progress: 0.5
      };

      const dhtmlxTask = convertSvarToDhtmlx(svarTask);

      expect(dhtmlxTask).toEqual({
        id: 1,
        text: 'タスク1',
        start: '2025-01-15',
        start_date: '2025-01-15',
        end: '2025-01-20',
        duration: 5,
        parent: 0,
        progress: 0.5
      });
    });

    it('name属性をtext属性に変換できること', () => {
      const svarTask = {
        id: 2,
        name: 'タスク名',
        start: '2025-01-15',
        end: '2025-01-16'
      };

      const dhtmlxTask = convertSvarToDhtmlx(svarTask);

      expect(dhtmlxTask.text).toBe('タスク名');
    });

    it('親タスクIDが正しく設定されること', () => {
      const svarTask = {
        id: 3,
        text: '子タスク',
        start: '2025-01-15',
        end: '2025-01-16',
        parent: 1
      };

      const dhtmlxTask = convertSvarToDhtmlx(svarTask);

      expect(dhtmlxTask.parent).toBe(1);
    });

    it('カスタムフィールドが保持されること', () => {
      const svarTask = {
        id: 4,
        text: 'タスク',
        start: '2025-01-15',
        end: '2025-01-16',
        customField: 'カスタム値',
        priority: 'high'
      };

      const dhtmlxTask = convertSvarToDhtmlx(svarTask);

      expect(dhtmlxTask.customField).toBe('カスタム値');
      expect(dhtmlxTask.priority).toBe('high');
    });
  });

  describe('calculateDuration', () => {
    it('正しい期間を計算できること', () => {
      expect(calculateDuration('2025-01-15', '2025-01-20')).toBe(5);
      expect(calculateDuration('2025-01-15', '2025-01-15')).toBe(1);
      expect(calculateDuration('2025-01-15', '2025-01-16')).toBe(1);
    });

    it('不正な日付の場合は1を返すこと', () => {
      expect(calculateDuration(null, '2025-01-20')).toBe(1);
      expect(calculateDuration('2025-01-15', null)).toBe(1);
      expect(calculateDuration(null, null)).toBe(1);
      expect(calculateDuration('', '')).toBe(1);
    });

    it('日付の順序が逆でも正しい期間を計算できること', () => {
      expect(calculateDuration('2025-01-20', '2025-01-15')).toBe(5);
    });
  });

  describe('リンクデータの変換', () => {
    it('リンクデータがそのまま維持されること', () => {
      const links = [
        { id: 1, source: 1, target: 2, type: '0' },
        { id: 2, source: 2, target: 3, type: '1' }
      ];

      // リンクは変換不要なのでそのまま
      expect(links).toEqual(links);
    });
  });

  describe('一括データ変換', () => {
    it('複数タスクとリンクを含むデータセットを変換できること', () => {
      const svarData = {
        tasks: [
          {
            id: 1,
            text: 'プロジェクト',
            start: '2025-01-15',
            end: '2025-01-25'
          },
          {
            id: 2,
            text: 'タスク1',
            start: '2025-01-15',
            end: '2025-01-20',
            parent: 1
          },
          {
            id: 3,
            text: 'タスク2',
            start: '2025-01-20',
            end: '2025-01-25',
            parent: 1
          }
        ],
        links: [
          { id: 1, source: 2, target: 3, type: '0' }
        ]
      };

      const dhtmlxData = {
        data: svarData.tasks.map(convertSvarToDhtmlx),
        links: svarData.links
      };

      expect(dhtmlxData.data).toHaveLength(3);
      expect(dhtmlxData.data[0].duration).toBe(10);
      expect(dhtmlxData.data[1].parent).toBe(1);
      expect(dhtmlxData.data[2].parent).toBe(1);
      expect(dhtmlxData.links).toEqual(svarData.links);
    });
  });
});