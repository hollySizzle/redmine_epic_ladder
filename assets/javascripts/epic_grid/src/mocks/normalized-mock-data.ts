import type { NormalizedAPIResponse } from '../types/normalized-api';

// 正規化APIモックデータ
// サンプルJSON: @vibes/logics/api_integration/normalized_api_response_sample.json

export const normalizedMockData: NormalizedAPIResponse = {
  entities: {
    epics: {
      epic1: {
        id: 'epic1',
        subject: '施設・ユーザー管理',
        description: '施設情報とユーザーアカウントの管理機能',
        status: 'open',
        fixed_version_id: null,
        feature_ids: ['f1', 'f2', 'f5'],
        statistics: {
          total_features: 3,
          completed_features: 1,
          total_user_stories: 3,
          total_child_items: 6,
          completion_percentage: 33.3
        },
        created_on: '2025-01-15T09:00:00Z',
        updated_on: '2025-10-01T14:30:00Z',
        tracker_id: 1
      },
      epic2: {
        id: 'epic2',
        subject: '開診スケジュール',
        description: '診療スケジュールの登録・管理機能',
        status: 'open',
        fixed_version_id: null,
        feature_ids: ['f3', 'f4'],
        statistics: {
          total_features: 2,
          completed_features: 1,
          total_user_stories: 2,
          total_child_items: 4,
          completion_percentage: 50.0
        },
        created_on: '2025-01-20T10:00:00Z',
        updated_on: '2025-09-28T16:45:00Z',
        tracker_id: 1
      }
    },

    versions: {
      v1: {
        id: 'v1',
        name: 'Version-1',
        description: '初期リリース版',
        effective_date: '2025-12-31',
        status: 'open',
        issue_count: 50,
        statistics: {
          total_issues: 50,
          completed_issues: 30,
          completion_rate: 60.0
        },
        created_on: '2025-01-10T08:00:00Z',
        updated_on: '2025-09-30T12:00:00Z'
      },
      v2: {
        id: 'v2',
        name: 'Version-2',
        description: '機能拡張版',
        effective_date: '2026-03-31',
        status: 'open',
        issue_count: 100,
        statistics: {
          total_issues: 100,
          completed_issues: 45,
          completion_rate: 45.0
        },
        created_on: '2025-02-01T09:00:00Z',
        updated_on: '2025-09-29T15:30:00Z'
      },
      v3: {
        id: 'v3',
        name: 'Version-3',
        description: '将来リリース予定',
        effective_date: '2026-06-30',
        status: 'open',
        issue_count: 0,
        statistics: {
          total_issues: 0,
          completed_issues: 0,
          completion_rate: 0.0
        },
        created_on: '2025-03-01T10:00:00Z',
        updated_on: '2025-03-01T10:00:00Z'
      }
    },

    features: {
      f1: {
        id: 'f1',
        title: '登録画面',
        description: '新規ユーザー登録機能',
        status: 'open',
        parent_epic_id: 'epic1',
        user_story_ids: ['us1', 'us5'],
        fixed_version_id: 'v1',
        version_source: 'direct',
        statistics: {
          total_user_stories: 1,
          completed_user_stories: 0,
          total_child_items: 4,
          child_items_by_type: {
            tasks: 2,
            tests: 1,
            bugs: 1
          },
          completion_percentage: 25.0
        },
        assigned_to_id: 101,
        priority_id: 2,
        created_on: '2025-02-10T11:00:00Z',
        updated_on: '2025-09-25T13:20:00Z',
        tracker_id: 2
      },
      f2: {
        id: 'f2',
        title: '一覧画面',
        description: 'ユーザー一覧表示機能',
        status: 'open',
        parent_epic_id: 'epic1',
        user_story_ids: ['us2', 'us6'],
        fixed_version_id: 'v1',
        version_source: 'direct',
        statistics: {
          total_user_stories: 1,
          completed_user_stories: 0,
          total_child_items: 1,
          child_items_by_type: {
            tasks: 1,
            tests: 0,
            bugs: 0
          },
          completion_percentage: 0.0
        },
        assigned_to_id: 102,
        priority_id: 2,
        created_on: '2025-02-12T14:00:00Z',
        updated_on: '2025-09-20T10:15:00Z',
        tracker_id: 2
      },
      f5: {
        id: 'f5',
        title: '編集画面',
        description: 'ユーザー情報編集機能',
        status: 'closed',
        parent_epic_id: 'epic1',
        user_story_ids: ['us3'],
        fixed_version_id: 'v2',
        version_source: 'direct',
        statistics: {
          total_user_stories: 1,
          completed_user_stories: 1,
          total_child_items: 1,
          child_items_by_type: {
            tasks: 1,
            tests: 0,
            bugs: 0
          },
          completion_percentage: 100.0
        },
        assigned_to_id: 101,
        priority_id: 2,
        created_on: '2025-03-05T09:30:00Z',
        updated_on: '2025-08-15T16:00:00Z',
        tracker_id: 2
      },
      f3: {
        id: 'f3',
        title: '診察室管理',
        description: '診察室の登録・編集機能',
        status: 'open',
        parent_epic_id: 'epic2',
        user_story_ids: ['us3', 'us7'],
        fixed_version_id: 'v2',
        version_source: 'direct',
        statistics: {
          total_user_stories: 1,
          completed_user_stories: 0,
          total_child_items: 1,
          child_items_by_type: {
            tasks: 1,
            tests: 0,
            bugs: 0
          },
          completion_percentage: 0.0
        },
        assigned_to_id: 102,
        priority_id: 2,
        created_on: '2025-03-08T10:00:00Z',
        updated_on: '2025-09-16T14:00:00Z',
        tracker_id: 2
      },
      f4: {
        id: 'f4',
        title: 'スケジュール登録',
        description: '診療スケジュール登録機能',
        status: 'open',
        parent_epic_id: 'epic2',
        user_story_ids: ['us4', 'us8'],
        fixed_version_id: 'v2',
        version_source: 'direct',
        statistics: {
          total_user_stories: 1,
          completed_user_stories: 0,
          total_child_items: 2,
          child_items_by_type: {
            tasks: 2,
            tests: 0,
            bugs: 0
          },
          completion_percentage: 0.0
        },
        assigned_to_id: 103,
        priority_id: 3,
        created_on: '2025-03-10T13:00:00Z',
        updated_on: '2025-09-18T11:45:00Z',
        tracker_id: 2
      }
    },

    user_stories: {
      us1: {
        id: 'us1',
        title: 'US#101 ユーザー登録フォーム',
        description: 'ユーザー情報入力フォームの実装',
        status: 'open',
        parent_feature_id: 'f1',
        task_ids: ['t1', 't2'],
        test_ids: ['test1'],
        bug_ids: ['b1'],
        fixed_version_id: 'v1',
        version_source: 'direct',
        expansion_state: true,
        statistics: {
          total_tasks: 2,
          completed_tasks: 1,
          total_tests: 1,
          passed_tests: 0,
          total_bugs: 1,
          resolved_bugs: 0,
          completion_percentage: 25.0
        },
        assigned_to_id: 201,
        estimated_hours: 16.0,
        done_ratio: 25,
        created_on: '2025-02-15T10:00:00Z',
        updated_on: '2025-09-22T14:30:00Z',
        tracker_id: 3
      },
      us2: {
        id: 'us2',
        title: 'US#102 ユーザー一覧表示',
        description: 'ユーザー情報の一覧表示機能',
        status: 'open',
        parent_feature_id: 'f2',
        task_ids: ['t3'],
        test_ids: [],
        bug_ids: [],
        fixed_version_id: 'v1',
        version_source: 'direct',
        expansion_state: false,
        statistics: {
          total_tasks: 1,
          completed_tasks: 0,
          total_tests: 0,
          passed_tests: 0,
          total_bugs: 0,
          resolved_bugs: 0,
          completion_percentage: 0.0
        },
        assigned_to_id: 202,
        estimated_hours: 8.0,
        done_ratio: 0,
        created_on: '2025-02-18T11:30:00Z',
        updated_on: '2025-09-15T09:00:00Z',
        tracker_id: 3
      },
      us3: {
        id: 'us3',
        title: 'US#103 ユーザー編集機能',
        description: 'ユーザー情報の更新機能',
        status: 'closed',
        parent_feature_id: 'f5',
        task_ids: ['t4'],
        test_ids: [],
        bug_ids: [],
        fixed_version_id: 'v2',
        version_source: 'direct',
        expansion_state: false,
        statistics: {
          total_tasks: 1,
          completed_tasks: 1,
          total_tests: 0,
          passed_tests: 0,
          total_bugs: 0,
          resolved_bugs: 0,
          completion_percentage: 100.0
        },
        assigned_to_id: 201,
        estimated_hours: 12.0,
        done_ratio: 100,
        created_on: '2025-03-08T14:00:00Z',
        updated_on: '2025-08-12T17:30:00Z',
        tracker_id: 3
      },
      us4: {
        id: 'us4',
        title: 'US#201 スケジュール登録画面',
        description: '診療スケジュール入力フォーム',
        status: 'open',
        parent_feature_id: 'f4',
        task_ids: ['t5', 't6'],
        test_ids: [],
        bug_ids: [],
        fixed_version_id: 'v2',
        version_source: 'direct',
        expansion_state: true,
        statistics: {
          total_tasks: 2,
          completed_tasks: 0,
          total_tests: 0,
          passed_tests: 0,
          total_bugs: 0,
          resolved_bugs: 0,
          completion_percentage: 0.0
        },
        assigned_to_id: 203,
        estimated_hours: 20.0,
        done_ratio: 0,
        created_on: '2025-03-12T15:30:00Z',
        updated_on: '2025-09-10T13:15:00Z',
        tracker_id: 3
      },
      us5: {
        id: 'us5',
        title: 'US#104 ユーザー認証強化',
        description: '2要素認証の実装',
        status: 'in_progress',
        parent_feature_id: 'f1',
        task_ids: ['t7', 't8'],
        test_ids: ['test2', 'test3'],
        bug_ids: [],
        fixed_version_id: 'v2',
        version_source: 'direct',
        expansion_state: true,
        statistics: {
          total_tasks: 2,
          completed_tasks: 1,
          total_tests: 2,
          passed_tests: 1,
          total_bugs: 0,
          resolved_bugs: 0,
          completion_percentage: 50.0
        },
        assigned_to_id: 201,
        estimated_hours: 24.0,
        done_ratio: 50,
        created_on: '2025-04-01T09:00:00Z',
        updated_on: '2025-09-25T11:30:00Z',
        tracker_id: 3
      },
      us6: {
        id: 'us6',
        title: 'US#105 パスワードリセット機能',
        description: 'メール経由のパスワードリセット',
        status: 'open',
        parent_feature_id: 'f2',
        task_ids: ['t9', 't10', 't11'],
        test_ids: ['test4'],
        bug_ids: ['b2'],
        fixed_version_id: 'v2',
        version_source: 'direct',
        expansion_state: true,
        statistics: {
          total_tasks: 3,
          completed_tasks: 0,
          total_tests: 1,
          passed_tests: 0,
          total_bugs: 1,
          resolved_bugs: 0,
          completion_percentage: 0.0
        },
        assigned_to_id: 202,
        estimated_hours: 16.0,
        done_ratio: 0,
        created_on: '2025-04-05T14:20:00Z',
        updated_on: '2025-09-23T16:45:00Z',
        tracker_id: 3
      },
      us7: {
        id: 'us7',
        title: 'US#202 診察室ステータス表示',
        description: '診察室の空き状況リアルタイム表示',
        status: 'in_progress',
        parent_feature_id: 'f3',
        task_ids: ['t12', 't13'],
        test_ids: ['test5'],
        bug_ids: ['b3'],
        fixed_version_id: 'v3',
        version_source: 'direct',
        expansion_state: true,
        statistics: {
          total_tasks: 2,
          completed_tasks: 1,
          total_tests: 1,
          passed_tests: 0,
          total_bugs: 1,
          resolved_bugs: 1,
          completion_percentage: 50.0
        },
        assigned_to_id: 203,
        estimated_hours: 18.0,
        done_ratio: 50,
        created_on: '2025-04-10T10:15:00Z',
        updated_on: '2025-09-28T13:20:00Z',
        tracker_id: 3
      },
      us8: {
        id: 'us8',
        title: 'US#203 スケジュール一覧表示',
        description: '週間スケジュールカレンダー表示',
        status: 'open',
        parent_feature_id: 'f4',
        task_ids: ['t14', 't15'],
        test_ids: ['test6', 'test7'],
        bug_ids: [],
        fixed_version_id: 'v3',
        version_source: 'direct',
        expansion_state: true,
        statistics: {
          total_tasks: 2,
          completed_tasks: 0,
          total_tests: 2,
          passed_tests: 0,
          total_bugs: 0,
          resolved_bugs: 0,
          completion_percentage: 0.0
        },
        assigned_to_id: 201,
        estimated_hours: 22.0,
        done_ratio: 0,
        created_on: '2025-04-15T11:45:00Z',
        updated_on: '2025-09-26T15:10:00Z',
        tracker_id: 3
      }
    },

    tasks: {
      t1: {
        id: 't1',
        title: 'バリデーション実装',
        description: '入力値のバリデーション処理実装',
        status: 'open',
        parent_user_story_id: 'us1',
        fixed_version_id: 'v1',
        assigned_to_id: 301,
        estimated_hours: 4.0,
        spent_hours: 3.5,
        done_ratio: 80,
        created_on: '2025-02-20T09:00:00Z',
        updated_on: '2025-09-20T16:00:00Z',
        tracker_id: 4
      },
      t2: {
        id: 't2',
        title: 'UI設計完了',
        description: '登録フォームのUI設計',
        status: 'closed',
        parent_user_story_id: 'us1',
        fixed_version_id: 'v1',
        assigned_to_id: 302,
        estimated_hours: 6.0,
        spent_hours: 5.0,
        done_ratio: 100,
        created_on: '2025-02-21T10:30:00Z',
        updated_on: '2025-08-25T14:00:00Z',
        tracker_id: 4
      },
      t3: {
        id: 't3',
        title: '一覧API実装',
        description: 'ユーザー一覧取得API実装',
        status: 'open',
        parent_user_story_id: 'us2',
        fixed_version_id: 'v1',
        assigned_to_id: 301,
        estimated_hours: 5.0,
        spent_hours: 0.0,
        done_ratio: 0,
        created_on: '2025-02-22T11:00:00Z',
        updated_on: '2025-09-10T10:00:00Z',
        tracker_id: 4
      },
      t4: {
        id: 't4',
        title: '編集フォーム作成',
        description: 'ユーザー編集フォームの実装',
        status: 'closed',
        parent_user_story_id: 'us3',
        fixed_version_id: 'v2',
        assigned_to_id: 302,
        estimated_hours: 8.0,
        spent_hours: 7.5,
        done_ratio: 100,
        created_on: '2025-03-10T13:00:00Z',
        updated_on: '2025-08-10T15:30:00Z',
        tracker_id: 4
      },
      t5: {
        id: 't5',
        title: 'カレンダーUI実装',
        description: 'スケジュール選択カレンダーUI',
        status: 'open',
        parent_user_story_id: 'us4',
        fixed_version_id: 'v2',
        assigned_to_id: 303,
        estimated_hours: 12.0,
        spent_hours: 2.0,
        done_ratio: 15,
        created_on: '2025-03-15T14:00:00Z',
        updated_on: '2025-09-05T11:30:00Z',
        tracker_id: 4
      },
      t6: {
        id: 't6',
        title: '繰り返し設定機能',
        description: '定期スケジュール設定機能',
        status: 'open',
        parent_user_story_id: 'us4',
        fixed_version_id: 'v2',
        assigned_to_id: 304,
        estimated_hours: 10.0,
        spent_hours: 0.0,
        done_ratio: 0,
        created_on: '2025-03-16T15:30:00Z',
        updated_on: '2025-09-01T09:00:00Z',
        tracker_id: 4
      },
      t7: {
        id: 't7',
        title: 'TOTPライブラリ導入',
        description: 'Time-based OTP生成ライブラリ選定と導入',
        status: 'closed',
        parent_user_story_id: 'us5',
        fixed_version_id: 'v2',
        assigned_to_id: 301,
        estimated_hours: 6.0,
        spent_hours: 5.5,
        done_ratio: 100,
        created_on: '2025-04-02T10:00:00Z',
        updated_on: '2025-09-20T14:00:00Z',
        tracker_id: 4
      },
      t8: {
        id: 't8',
        title: 'QRコード生成機能',
        description: '認証用QRコード生成UI実装',
        status: 'in_progress',
        parent_user_story_id: 'us5',
        fixed_version_id: 'v2',
        assigned_to_id: 302,
        estimated_hours: 8.0,
        spent_hours: 4.0,
        done_ratio: 50,
        created_on: '2025-04-03T11:30:00Z',
        updated_on: '2025-09-24T16:20:00Z',
        tracker_id: 4
      },
      t9: {
        id: 't9',
        title: 'トークン生成処理',
        description: 'パスワードリセット用ワンタイムトークン生成',
        status: 'open',
        parent_user_story_id: 'us6',
        fixed_version_id: 'v2',
        assigned_to_id: 303,
        estimated_hours: 4.0,
        spent_hours: 0.0,
        done_ratio: 0,
        created_on: '2025-04-06T09:15:00Z',
        updated_on: '2025-09-22T10:30:00Z',
        tracker_id: 4
      },
      t10: {
        id: 't10',
        title: 'メール送信機能',
        description: 'リセットメール送信処理実装',
        status: 'open',
        parent_user_story_id: 'us6',
        fixed_version_id: 'v2',
        assigned_to_id: 304,
        estimated_hours: 6.0,
        spent_hours: 0.0,
        done_ratio: 0,
        created_on: '2025-04-07T14:00:00Z',
        updated_on: '2025-09-21T11:45:00Z',
        tracker_id: 4
      },
      t11: {
        id: 't11',
        title: 'リセットフォーム作成',
        description: '新パスワード入力フォーム実装',
        status: 'open',
        parent_user_story_id: 'us6',
        fixed_version_id: 'v2',
        assigned_to_id: 301,
        estimated_hours: 5.0,
        spent_hours: 0.0,
        done_ratio: 0,
        created_on: '2025-04-08T10:20:00Z',
        updated_on: '2025-09-20T09:00:00Z',
        tracker_id: 4
      },
      t12: {
        id: 't12',
        title: 'WebSocket接続実装',
        description: 'リアルタイム更新用WebSocket接続',
        status: 'closed',
        parent_user_story_id: 'us7',
        fixed_version_id: 'v3',
        assigned_to_id: 302,
        estimated_hours: 8.0,
        spent_hours: 7.0,
        done_ratio: 100,
        created_on: '2025-04-11T11:00:00Z',
        updated_on: '2025-09-27T15:30:00Z',
        tracker_id: 4
      },
      t13: {
        id: 't13',
        title: 'ステータス表示UI',
        description: '診察室ステータス表示コンポーネント',
        status: 'in_progress',
        parent_user_story_id: 'us7',
        fixed_version_id: 'v3',
        assigned_to_id: 303,
        estimated_hours: 7.0,
        spent_hours: 3.5,
        done_ratio: 50,
        created_on: '2025-04-12T09:30:00Z',
        updated_on: '2025-09-26T12:15:00Z',
        tracker_id: 4
      },
      t14: {
        id: 't14',
        title: 'カレンダーライブラリ選定',
        description: 'React用カレンダーライブラリ調査・選定',
        status: 'open',
        parent_user_story_id: 'us8',
        fixed_version_id: 'v3',
        assigned_to_id: 304,
        estimated_hours: 4.0,
        spent_hours: 0.0,
        done_ratio: 0,
        created_on: '2025-04-16T10:00:00Z',
        updated_on: '2025-09-25T13:40:00Z',
        tracker_id: 4
      },
      t15: {
        id: 't15',
        title: 'スケジュールデータ取得API',
        description: '週間スケジュール取得API実装',
        status: 'open',
        parent_user_story_id: 'us8',
        fixed_version_id: 'v3',
        assigned_to_id: 301,
        estimated_hours: 6.0,
        spent_hours: 0.0,
        done_ratio: 0,
        created_on: '2025-04-17T11:15:00Z',
        updated_on: '2025-09-24T14:50:00Z',
        tracker_id: 4
      }
    },

    tests: {
      test1: {
        id: 'test1',
        title: '単体テスト作成',
        description: 'バリデーション機能の単体テスト',
        status: 'open',
        parent_user_story_id: 'us1',
        fixed_version_id: 'v1',
        test_result: 'pending',
        assigned_to_id: 401,
        created_on: '2025-02-25T10:00:00Z',
        updated_on: '2025-09-12T13:00:00Z',
        tracker_id: 5
      },
      test2: {
        id: 'test2',
        title: 'TOTP認証テスト',
        description: 'OTPコード検証ロジックのテスト',
        status: 'closed',
        parent_user_story_id: 'us5',
        fixed_version_id: 'v2',
        test_result: 'passed',
        assigned_to_id: 401,
        created_on: '2025-04-04T09:30:00Z',
        updated_on: '2025-09-21T15:00:00Z',
        tracker_id: 5
      },
      test3: {
        id: 'test3',
        title: 'QRコード表示テスト',
        description: 'QRコード生成・表示の結合テスト',
        status: 'in_progress',
        parent_user_story_id: 'us5',
        fixed_version_id: 'v2',
        test_result: 'pending',
        assigned_to_id: 402,
        created_on: '2025-04-05T10:15:00Z',
        updated_on: '2025-09-25T11:30:00Z',
        tracker_id: 5
      },
      test4: {
        id: 'test4',
        title: 'パスワードリセット E2E',
        description: 'メール送信からリセット完了までのE2Eテスト',
        status: 'open',
        parent_user_story_id: 'us6',
        fixed_version_id: 'v2',
        test_result: 'pending',
        assigned_to_id: 403,
        created_on: '2025-04-09T11:00:00Z',
        updated_on: '2025-09-22T14:20:00Z',
        tracker_id: 5
      },
      test5: {
        id: 'test5',
        title: 'WebSocket接続テスト',
        description: 'リアルタイム更新の接続・切断テスト',
        status: 'in_progress',
        parent_user_story_id: 'us7',
        fixed_version_id: 'v3',
        test_result: 'pending',
        assigned_to_id: 401,
        created_on: '2025-04-13T09:45:00Z',
        updated_on: '2025-09-27T16:10:00Z',
        tracker_id: 5
      },
      test6: {
        id: 'test6',
        title: 'カレンダー表示テスト',
        description: '週間カレンダーレンダリングテスト',
        status: 'open',
        parent_user_story_id: 'us8',
        fixed_version_id: 'v3',
        test_result: 'pending',
        assigned_to_id: 402,
        created_on: '2025-04-18T10:30:00Z',
        updated_on: '2025-09-25T12:45:00Z',
        tracker_id: 5
      },
      test7: {
        id: 'test7',
        title: 'スケジュールAPI統合テスト',
        description: 'APIからデータ取得してカレンダー表示まで',
        status: 'open',
        parent_user_story_id: 'us8',
        fixed_version_id: 'v3',
        test_result: 'pending',
        assigned_to_id: 403,
        created_on: '2025-04-19T11:15:00Z',
        updated_on: '2025-09-24T13:50:00Z',
        tracker_id: 5
      }
    },

    bugs: {
      b1: {
        id: 'b1',
        title: 'バリデーションエラー修正',
        description: 'メールアドレス形式チェックの不具合',
        status: 'open',
        parent_user_story_id: 'us1',
        fixed_version_id: 'v1',
        severity: 'minor',
        assigned_to_id: 301,
        created_on: '2025-09-18T16:30:00Z',
        updated_on: '2025-09-20T10:00:00Z',
        tracker_id: 6
      },
      b2: {
        id: 'b2',
        title: 'メールテンプレート文字化け',
        description: 'リセットメールの日本語が文字化けする',
        status: 'open',
        parent_user_story_id: 'us6',
        fixed_version_id: 'v2',
        severity: 'major',
        assigned_to_id: 302,
        created_on: '2025-09-23T10:15:00Z',
        updated_on: '2025-09-24T14:30:00Z',
        tracker_id: 6
      },
      b3: {
        id: 'b3',
        title: 'WebSocket切断時再接続失敗',
        description: 'ネットワーク切断後の自動再接続が動作しない',
        status: 'closed',
        parent_user_story_id: 'us7',
        fixed_version_id: 'v3',
        severity: 'critical',
        assigned_to_id: 303,
        created_on: '2025-09-26T09:00:00Z',
        updated_on: '2025-09-28T16:45:00Z',
        tracker_id: 6
      }
    }
  },

  grid: {
    // Epic × Feature × Version の3次元インデックス
    index: {
      'epic1:f1:v1': ['us1'],
      'epic1:f1:v2': ['us5'],
      'epic1:f1:v3': [],
      'epic1:f2:v1': ['us2'],
      'epic1:f2:v2': ['us6'],
      'epic1:f2:v3': [],
      'epic1:f5:v1': [],
      'epic1:f5:v2': ['us3'],
      'epic1:f5:v3': [],
      'epic2:f3:v1': [],
      'epic2:f3:v2': [],
      'epic2:f3:v3': ['us7'],
      'epic2:f4:v1': [],
      'epic2:f4:v2': ['us4'],
      'epic2:f4:v3': ['us8']
    },
    epic_order: ['epic1', 'epic2'],
    feature_order_by_epic: {
      epic1: ['f1', 'f2', 'f5'],
      epic2: ['f3', 'f4']
    },
    version_order: ['v1', 'v2', 'v3']
  },

  metadata: {
    project: {
      id: 1,
      name: '医療予約システム',
      identifier: 'medical-reservation',
      description: '診療所向け予約管理システム',
      created_on: '2025-01-01T00:00:00Z'
    },

    user_permissions: {
      view_issues: true,
      edit_issues: true,
      add_issues: true,
      delete_issues: false,
      manage_versions: false,
      manage_project: false
    },

    grid_configuration: {
      default_expanded: false,
      show_statistics: true,
      show_closed_issues: true,
      columns: [
        {
          id: 'backlog',
          name: 'バックログ',
          status_ids: [1],
          position: 1
        },
        {
          id: 'in_progress',
          name: '進行中',
          status_ids: [2, 3],
          position: 2
        },
        {
          id: 'done',
          name: '完了',
          status_ids: [5],
          position: 3
        }
      ]
    },

    api_version: 'v2',
    timestamp: new Date().toISOString(),
    request_id: 'req_mock_' + Math.random().toString(36).substring(7)
  }
};
