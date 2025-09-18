import React from "react";
import { Button } from "flowbite-react";

/**
 * 列設定ボタンコンポーネント
 * 列設定パネルの表示切り替えを管理
 */
function ColumnSettingsButton({
  showColumnSettings,
  onToggleColumnSettings,
}) {
  return (
    <Button
      onClick={onToggleColumnSettings}
      color="gray"
      size="xs"
      className="w-full sm:w-auto whitespace-nowrap"
    >
      列の設定
    </Button>
  );
}

export default ColumnSettingsButton;