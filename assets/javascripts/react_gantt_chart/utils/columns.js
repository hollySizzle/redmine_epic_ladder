/**
 * ───────────────────────────────────────────────────────────
 *  列設定関連ユーティリティ
 * ───────────────────────────────────────────────────────────
 */

export const BASE_COLUMN_DEFS = {
  id: {
    id: "id",
    header: "ID",
    width: 50,
    align: "center",
  },
  text: {
    id: "text",
    header: "タスク名",
    flexGrow: 3,
  },
  tracker_name: {
    id: "tracker_name",
    header: "トラッカー",
    width: 100,
    align: "center",
    formatter: (v) => v || "-",
  },
  status_name: {
    id: "status_name",
    header: "ステータス",
    width: 100,
    align: "center",
  },
  assigned_to_name: {
    id: "assigned_to_name",
    header: "担当者",
    width: 100,
    align: "center",
  },
  start: {
    id: "start",
    header: "開始日",
    width: 100,
    align: "center",
    formatter: (v) => (v ? new Date(v).toLocaleDateString() : "-"),
  },
  end: {
    id: "end",
    header: "終了日",
    width: 100,
    align: "center",
    formatter: (v) => (v ? new Date(v).toLocaleDateString() : "-"),
  },
  details: {
    id: "details",
    header: "説明",
    flexGrow: 3,
    align: "left",
  },
  action: {
    id: "action",
    header: "",
    width: 50,
    align: "center",
  },
};

/**
 * タスク配列を見てカスタムフィールド列を生成
 */
export function buildCustomFieldDefs(tasks) {
  if (!Array.isArray(tasks) || tasks.length === 0) return {};

  const sample = tasks.find((t) => t.custom_fields);
  if (!sample) return {};

  const defs = {};
  Object.entries(sample.custom_fields).forEach(([key, field]) => {
    defs[`custom_fields_${key}`] = {
      id: `custom_fields_${key}`,
      header: field.name,
      width: 100,
      align: "center",
      formatter: (v) => v || "-",
    };
  });
  return defs;
}
