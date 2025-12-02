# frozen_string_literal: true

# ============================================================
# view_customize プラグインの無効化
# ============================================================
#
# テスト環境では view_customize プラグインを無効化します。
#
# 理由:
# - epic_ladder プラグインのテストには不要
# - view_customizes テーブルが存在しないエラーを回避
# - テストの実行速度向上
#
# ============================================================

# ViewCustomize モデルが定義されている場合、テーブルアクセスを無効化
if defined?(ViewCustomize)
  ViewCustomize.class_eval do
    # テーブル存在チェックを常に false に
    def self.table_exists?
      false
    end

    # all クエリを空配列に
    def self.all
      ViewCustomize.none
    end

    # where クエリを空のリレーションに
    def self.where(*args)
      ViewCustomize.none
    end

    # find_by を nil に
    def self.find_by(*args)
      nil
    end

    # find を nil に
    def self.find(*args)
      nil
    end
  end

  puts "[INFO] ✅ view_customize プラグインを無効化しました (モデルパッチ適用)"
end

# RedmineViewCustomize::ViewHook を無効化（レイアウトでの呼び出しをスキップ）
if defined?(RedmineViewCustomize::ViewHook)
  RedmineViewCustomize::ViewHook.class_eval do
    # 全てのビューフックメソッドを空文字列に
    def view_layouts_base_html_head(context)
      ''
    end

    def view_layouts_base_body_bottom(context)
      ''
    end
  end

  puts "[INFO] ✅ RedmineViewCustomize::ViewHook を無効化しました (class_evalパッチ適用)"
end
