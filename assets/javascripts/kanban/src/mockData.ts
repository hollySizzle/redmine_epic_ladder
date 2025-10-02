import { EpicData, VersionData, EpicVersionCellData } from './components/EpicVersion/EpicVersionGrid';

export const mockEpics: EpicData[] = [
  { id: 'epic1', name: '施設・ユーザー管理' },
  { id: 'epic2', name: '開診スケジュール' }
];

export const mockVersions: VersionData[] = [
  { id: 'v1', name: 'Version-1' },
  { id: 'v2', name: 'Version-2' },
  { id: 'v3', name: 'Version-3' },
  { id: 'none', name: 'No Version' }
];

export const mockCells: EpicVersionCellData[] = [
  // Epic 1 - Version 1
  {
    epicId: 'epic1',
    versionId: 'v1',
    features: [
      {
        id: 'f1',
        title: '登録画面',
        status: 'open',
        stories: [
          {
            id: 'us1',
            title: 'US#101 ユーザー登録フォーム',
            status: 'open',
            tasks: [
              { id: 't1', title: 'バリデーション実装', status: 'open' },
              { id: 't2', title: 'UI設計完了', status: 'closed' }
            ],
            tests: [
              { id: 'test1', title: '単体テスト作成', status: 'open' }
            ],
            bugs: [
              { id: 'b1', title: 'バリデーションエラー修正', status: 'open' }
            ]
          }
        ]
      },
      {
        id: 'f2',
        title: '一覧画面',
        status: 'open',
        stories: [
          {
            id: 'us2',
            title: 'US#102 ユーザー一覧表示',
            status: 'open',
            tasks: [
              { id: 't3', title: '一覧API実装', status: 'open' }
            ],
            tests: [],
            bugs: []
          }
        ]
      }
    ]
  },
  // Epic 1 - Version 2
  {
    epicId: 'epic1',
    versionId: 'v2',
    features: [
      {
        id: 'f3',
        title: '編集画面',
        status: 'closed',
        stories: [
          {
            id: 'us3',
            title: 'US#103 ユーザー編集機能',
            status: 'closed',
            tasks: [
              { id: 't4', title: '編集フォーム作成', status: 'closed' }
            ],
            tests: [],
            bugs: []
          }
        ]
      }
    ]
  },
  // Epic 1 - Version 3 (空)
  {
    epicId: 'epic1',
    versionId: 'v3',
    features: []
  },
  // Epic 1 - No Version (空)
  {
    epicId: 'epic1',
    versionId: 'none',
    features: []
  },
  // Epic 2 - Version 1 (空)
  {
    epicId: 'epic2',
    versionId: 'v1',
    features: []
  },
  // Epic 2 - Version 2
  {
    epicId: 'epic2',
    versionId: 'v2',
    features: [
      {
        id: 'f4',
        title: 'スケジュール登録',
        status: 'open',
        stories: [
          {
            id: 'us4',
            title: 'US#201 スケジュール登録画面',
            status: 'open',
            tasks: [
              { id: 't5', title: 'カレンダーUI実装', status: 'open' },
              { id: 't6', title: '繰り返し設定機能', status: 'open' }
            ],
            tests: [],
            bugs: []
          }
        ]
      }
    ]
  },
  // Epic 2 - Version 3 (空)
  {
    epicId: 'epic2',
    versionId: 'v3',
    features: []
  },
  // Epic 2 - No Version (空)
  {
    epicId: 'epic2',
    versionId: 'none',
    features: []
  }
];
