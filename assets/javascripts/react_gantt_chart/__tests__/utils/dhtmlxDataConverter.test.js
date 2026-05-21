import {
  convertSvarToGantt,
  convertGanttToSvar,
  convertForBulkUpdate
} from '../../utils/dhtmlxDataConverter';

describe('dhtmlxDataConverter', () => {
  describe('F001: データ変換機能', () => {
    describe('convertSvarToGantt', () => {
      it('SVAR形式のタスクをDHTMLX Gantt形式に変換する', () => {
        const svarTasks = [
          {
            id: 1,
            text: 'タスク1',
            start: '2024-01-01',
            end: '2024-01-05',
            progress: 0.5,
            parent: 0,
            editable: true,
            is_closed: false,
            priority: '通常',
            status: '新規',
            status_label: '新規',
            priority_label: '通常',
            assignee: 'ユーザー1',
            issue_id: '123'
          }
        ];

        const result = convertSvarToGantt(svarTasks);

        expect(result).toHaveLength(1);
        expect(result[0]).toMatchObject({
          id: 1,
          text: 'タスク1',
          start_date: expect.any(Date),
          end_date: expect.any(Date),
          progress: 0.5,
          parent: 0,
          editable: true,
          redmine_data: {
            is_closed: false,
            priority_name: '通常',
            status_name: '新規',
            status_label: '新規',
            priority_label: '通常',
            assigned_to_name: 'ユーザー1',
            issue_id: '123',
            end_date: '2024-01-05'
          }
        });
      });

      it('日付を正しくDateオブジェクトに変換する', () => {
        const svarTasks = [
          {
            id: 1,
            text: 'タスク',
            start: '2024-01-01',
            end: '2024-01-05'
          }
        ];

        const result = convertSvarToGantt(svarTasks);
        const task = result[0];

        expect(task.start_date).toBeInstanceOf(Date);
        expect(task.end_date).toBeInstanceOf(Date);
        expect(task.start_date.toISOString()).toBe('2024-01-01T00:00:00.000Z');
        expect(task.end_date.toISOString()).toBe('2024-01-05T00:00:00.000Z');
      });

      it('無効な日付の場合はデフォルト値を使用する', () => {
        const svarTasks = [
          {
            id: 1,
            text: 'タスク',
            start: 'invalid-date',
            end: null
          }
        ];

        const result = convertSvarToGantt(svarTasks);
        const task = result[0];

        expect(task.start_date).toBeInstanceOf(Date);
        expect(task.end_date).toBeInstanceOf(Date);
        expect(isNaN(task.start_date.getTime())).toBe(false);
        expect(isNaN(task.end_date.getTime())).toBe(false);
      });

      it('進捗率を0-1の範囲に正規化する', () => {
        const svarTasks = [
          { id: 1, text: 'タスク1', progress: 50 },
          { id: 2, text: 'タスク2', progress: 0.5 },
          { id: 3, text: 'タスク3', progress: 150 },
          { id: 4, text: 'タスク4', progress: -10 }
        ];

        const result = convertSvarToGantt(svarTasks);

        expect(result[0].progress).toBe(0.5);
        expect(result[1].progress).toBe(0.5);
        expect(result[2].progress).toBe(1);
        expect(result[3].progress).toBe(0);
      });

      it('カスタムフィールドを正しく変換する', () => {
        const svarTasks = [
          {
            id: 1,
            text: 'タスク',
            custom_fields: {
              cf_1: {
                id: 1,
                name: 'カスタムフィールド1',
                value: '値1',
                type: 'string'
              },
              cf_2: {
                id: 2,
                name: 'カスタムフィールド2',
                value: '100',
                type: 'int'
              }
            }
          }
        ];

        const result = convertSvarToGantt(svarTasks);
        const task = result[0];

        expect(task.redmine_data.custom_fields).toEqual(svarTasks[0].custom_fields);
      });
    });

    describe('convertGanttToSvar', () => {
      it('DHTMLX Gantt形式のタスクをSVAR形式に変換する', () => {
        const ganttTasks = [
          {
            id: 1,
            text: 'タスク1',
            start_date: new Date('2024-01-01'),
            end_date: new Date('2024-01-05'),
            progress: 0.5,
            parent: 0,
            editable: true,
            redmine_data: {
              is_closed: false,
              priority_name: '通常',
              status_name: '新規',
              assigned_to_name: 'ユーザー1',
              issue_id: '123'
            }
          }
        ];

        const result = convertGanttToSvar(ganttTasks);

        expect(result).toHaveLength(1);
        expect(result[0]).toMatchObject({
          id: 1,
          text: 'タスク1',
          start: '2024-01-01',
          end: '2024-01-05',
          progress: 0.5,
          parent: 0,
          editable: true,
          is_closed: false,
          priority: '通常',
          status: '新規',
          assignee: 'ユーザー1',
          issue_id: '123'
        });
      });

      it('DateオブジェクトをYYYY-MM-DD形式の文字列に変換する', () => {
        const ganttTasks = [
          {
            id: 1,
            text: 'タスク',
            start_date: new Date('2024-01-01T10:30:00'),
            end_date: new Date('2024-12-31T18:45:00')
          }
        ];

        const result = convertGanttToSvar(ganttTasks);

        expect(result[0].start).toBe('2024-01-01');
        expect(result[0].end).toBe('2024-12-31');
      });

      it('カスタムフィールドをルートレベルに展開する', () => {
        const ganttTasks = [
          {
            id: 1,
            text: 'タスク',
            redmine_data: {
              custom_fields: {
                cf_1: {
                  id: 1,
                  name: 'カスタムフィールド1',
                  value: '値1'
                }
              }
            }
          }
        ];

        const result = convertGanttToSvar(ganttTasks);

        expect(result[0].custom_fields).toEqual(ganttTasks[0].redmine_data.custom_fields);
      });
    });

    describe('convertForBulkUpdate', () => {
      it('変更されたタスクを一括更新用に変換する', () => {
        const modifiedIds = ['1', '2'];
        const getTaskById = (id) => ({
          id: parseInt(id),
          text: `タスク${id}`,
          start_date: new Date('2024-01-01'),
          end_date: new Date('2024-01-05'),
          progress: 0.5,
          parent: 0,
          redmine_data: {
            issue_id: `12${id}`,
            custom_fields: {
              cf_1: { id: 1, value: '値' }
            }
          }
        });
        const pendingOrder = new Map();

        const result = convertForBulkUpdate(modifiedIds, getTaskById, pendingOrder);

        expect(result).toHaveLength(2);
        expect(result[0]).toMatchObject({
          id: '121',
          subject: 'タスク1',
          start_date: '2024-01-01',
          due_date: '2024-01-05',
          done_ratio: 50,
          parent_issue_id: null,
          custom_field_values: { 1: '値' }
        });
      });

      it('親タスクIDを正しく変換する', () => {
        const modifiedIds = ['1'];
        const getTaskById = (id) => ({
          id: 1,
          text: '子タスク',
          parent: 2,
          redmine_data: {
            issue_id: '123',
            parent_issue_id: '456'
          }
        });

        const result = convertForBulkUpdate(modifiedIds, getTaskById, new Map());

        expect(result[0].parent_issue_id).toBe('456');
      });

      it('タスクのソート順序を含める', () => {
        const modifiedIds = ['1'];
        const getTaskById = (id) => ({
          id: 1,
          text: 'タスク',
          redmine_data: { issue_id: '123' }
        });
        const pendingOrder = new Map([['1', { parent: 0, tindex: 5 }]]);

        const result = convertForBulkUpdate(modifiedIds, getTaskById, pendingOrder);

        expect(result[0].sort_order).toEqual({ parent: 0, index: 5 });
      });

      it('リンク情報を正しく変換する', () => {
        const modifiedIds = ['link_1'];
        const getTaskById = () => null;
        const pendingOrder = new Map();
        
        // リンク情報をグローバルにganttから取得する想定
        global.gantt = {
          getLink: (id) => ({
            id: '1',
            source: 1,
            target: 2,
            type: '0'
          })
        };

        const result = convertForBulkUpdate(modifiedIds, getTaskById, pendingOrder);

        expect(result).toHaveLength(1);
        expect(result[0]).toMatchObject({
          id: '1',
          source: 1,
          target: 2,
          type: '0',
          _isLink: true
        });
      });
    });
  });
});