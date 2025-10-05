# frozen_string_literal: true

# MSW契約スキーマ定義
# handlers.tsから抽出したレスポンス構造の期待値
module MswContracts
  # Epic作成レスポンス契約
  CREATE_EPIC_RESPONSE = {
    success: true,
    data: {
      created_entity: {
        id: String,
        subject: String,
        description: String,
        status: String, # 'open' | 'closed'
        fixed_version_id: [String, NilClass], # nilも許容
        feature_ids: Array,
        statistics: Hash,
        created_on: String, # ISO8601
        updated_on: String,
        tracker_id: Integer
      },
      updated_entities: {
        epics: Hash # { [id]: Epic }
      },
      grid_updates: {
        epic_order: Array # Epic ID配列
      }
    },
    meta: {
      timestamp: String,
      request_id: [String, NilClass], # nilも許容（テスト環境）
      api_version: String,
      execution_time: [Float, NilClass]
    }
  }.freeze

  # Version作成レスポンス契約
  CREATE_VERSION_RESPONSE = {
    success: true,
    data: {
      created_entity: {
        id: String,
        name: String,
        description: String,
        effective_date: [String, NilClass],
        due_date: [String, NilClass],
        status: String,
        created_on: String,
        updated_on: String
      },
      updated_entities: {
        versions: Hash
      },
      grid_updates: {
        version_order: Array
      }
    },
    meta: {
      timestamp: String,
      request_id: [String, NilClass],
      api_version: String,
      execution_time: [Float, NilClass]
    }
  }.freeze

  # Feature作成レスポンス契約
  CREATE_FEATURE_RESPONSE = {
    success: true,
    data: {
      created_entity: {
        id: String,
        title: String,
        description: String,
        status: String,
        parent_epic_id: String,
        user_story_ids: Array,
        fixed_version_id: [String, NilClass],
        version_source: String,
        statistics: Hash,
        assigned_to_id: [Integer, NilClass],
        priority_id: [Integer, NilClass],
        created_on: String,
        updated_on: String,
        tracker_id: Integer
      },
      updated_entities: {
        epics: Hash,
        features: Hash
        # versions: Hash # optional - nilの場合は存在しない
      },
      grid_updates: {
        index: Hash # { [cellKey]: [featureIds] }
      }
    },
    meta: {
      timestamp: String,
      request_id: [String, NilClass],
      api_version: String,
      execution_time: [Float, NilClass]
    }
  }.freeze

  # UserStory作成レスポンス契約
  CREATE_USER_STORY_RESPONSE = {
    success: true,
    data: {
      created_entity: {
        id: String,
        title: String,
        description: String,
        status: String,
        parent_feature_id: String,
        task_ids: Array,
        test_ids: Array,
        bug_ids: Array,
        fixed_version_id: [String, NilClass],
        version_source: String,
        expansion_state: [TrueClass, FalseClass],
        statistics: Hash,
        assigned_to_id: [Integer, NilClass],
        estimated_hours: [Float, NilClass],
        created_on: String,
        updated_on: String,
        tracker_id: Integer
      },
      updated_entities: {
        features: Hash,
        user_stories: Hash
      }
    },
    meta: {
      timestamp: String,
      request_id: [String, NilClass],
      api_version: String,
      execution_time: [Float, NilClass]
    }
  }.freeze

  # Task作成レスポンス契約
  CREATE_TASK_RESPONSE = {
    success: true,
    data: {
      created_entity: {
        id: String,
        title: String,
        description: String,
        status: String,
        parent_user_story_id: String,
        fixed_version_id: [String, NilClass],
        assigned_to_id: [Integer, NilClass],
        estimated_hours: [Float, NilClass],
        spent_hours: [Float, NilClass],
        done_ratio: Integer,
        created_on: String,
        updated_on: String,
        tracker_id: Integer
      },
      updated_entities: {
        user_stories: Hash,
        tasks: Hash
      }
    },
    meta: {
      timestamp: String,
      request_id: [String, NilClass],
      api_version: String,
      execution_time: [Float, NilClass]
    }
  }.freeze

  # Test作成レスポンス契約
  CREATE_TEST_RESPONSE = {
    success: true,
    data: {
      created_entity: {
        id: String,
        title: String,
        description: String,
        status: String,
        parent_user_story_id: String,
        fixed_version_id: [String, NilClass],
        test_result: String, # 'pending' | 'passed' | 'failed'
        assigned_to_id: [Integer, NilClass],
        created_on: String,
        updated_on: String,
        tracker_id: Integer
      },
      updated_entities: {
        user_stories: Hash,
        tests: Hash
      }
    },
    meta: {
      timestamp: String,
      request_id: String
    }
  }.freeze

  # Bug作成レスポンス契約
  CREATE_BUG_RESPONSE = {
    success: true,
    data: {
      created_entity: {
        id: String,
        title: String,
        description: String,
        status: String,
        parent_user_story_id: String,
        fixed_version_id: [String, NilClass],
        severity: String,
        assigned_to_id: [Integer, NilClass],
        created_on: String,
        updated_on: String,
        tracker_id: Integer
      },
      updated_entities: {
        user_stories: Hash,
        bugs: Hash
      }
    },
    meta: {
      timestamp: String,
      request_id: String
    }
  }.freeze

  # Feature移動レスポンス契約
  MOVE_FEATURE_RESPONSE = {
    success: true,
    updated_entities: {
      features: Hash
    },
    updated_grid_index: Hash,
    propagation_result: {
      affected_issue_ids: Array,
      conflicts: Array
    }
  }.freeze

  # エラーレスポンス契約
  ERROR_RESPONSE = {
    success: false,
    error: {
      code: String,
      message: String,
      details: Hash
    },
    metadata: {
      timestamp: String,
      request_id: String
    }
  }.freeze
end
