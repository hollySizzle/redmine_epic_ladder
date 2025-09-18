import React from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "./components/gantt/dhtmlx-gantt-custom.scss";
import "../../stylesheets/react_gantt_chart.css";

// ビルド時間を定数として追加
// 注: 実際の運用では、ビルドプロセス中にこの値が動的に更新されるようにすべきです
const BUILD_TIME = new Date().toLocaleString("ja-JP");

document.addEventListener("DOMContentLoaded", () => {
  const container = document.getElementById("react-gantt-chart-app");
  if (container) {
    const root = createRoot(container);
    root.render(<App buildTime={BUILD_TIME} />);
  } else {
    console.error("マウントポイント #react-gantt-chart-app が見つかりません。");
  }
});
