/**
 * リサイザー位置を管理するユーティリティ
 */

const COOKIE_KEY = "redmine_react_gantt_resizer_positions";

/**
 * Cookieからリサイザー位置を読み込む
 * @returns {Object} リサイザー位置のマッピング
 */
export const loadResizerPositions = () => {
  try {
    const cookie = document.cookie
      .split(";")
      .find((row) => row.trim().startsWith(`${COOKIE_KEY}=`));
    if (cookie) {
      const value = cookie.split("=")[1];
      return JSON.parse(decodeURIComponent(value));
    }
  } catch (e) {
    console.error("Failed to load resizer positions:", e);
  }
  return {};
};

/**
 * リサイザー位置をCookieに保存
 * @param {Object} positions リサイザー位置のマッピング
 */
export const saveResizerPositions = (positions) => {
  try {
    const value = encodeURIComponent(JSON.stringify(positions));
    document.cookie = `${COOKIE_KEY}=${value};path=/;max-age=1814400`;
    console.log("Resizer positions saved:", positions);
  } catch (e) {
    console.error("Failed to save resizer positions:", e);
  }
};

/**
 * リサイザー位置の設定をリセット
 * @returns {boolean} リセットが成功したかどうか
 */
export const resetResizerPositions = () => {
  try {
    // Cookieを削除
    document.cookie = `${COOKIE_KEY}=;path=/;expires=Thu, 01 Jan 1970 00:00:01 GMT`;

    // リロード確認
    if (window.confirm("リセットしました。リロードしますか？")) {
      window.location.reload();
    }

    return true;
  } catch (e) {
    console.error("Failed to reset resizer positions:", e);
    return false;
  }
};

/**
 * リサイザーの監視を設定
 * @returns {Object} restore/disconnect関数を含むオブジェクト
 */
export const setupResizerObserver = () => {
  let observer;
  const positions = loadResizerPositions();

  const observeResizers = () => {
    // 既存のObserverをクリーンアップ
    if (observer) {
      observer.disconnect();
    }

    observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (
          mutation.type === "attributes" &&
          mutation.attributeName === "style"
        ) {
          const element = mutation.target;

          // リサイザーの場合
          if (element.classList.contains("wx-resizer-x")) {
            const style = window.getComputedStyle(element);
            const left = style.left;

            const resizerClass = Array.from(element.classList).find((cls) =>
              cls.startsWith("x2-")
            );
            if (resizerClass) {
              positions[`resizer-${resizerClass}`] = left;

              // 対応するテーブルラッパーの幅を取得・保存
              const tableWrapper = document.querySelector(
                `.wx-table-wrapper.${resizerClass}`
              );
              if (tableWrapper) {
                const wrapperStyle = window.getComputedStyle(tableWrapper);
                positions[`wrapper-${resizerClass}`] = wrapperStyle.width;
              }
              saveResizerPositions(positions);
            }
          }

          // テーブルラッパーの場合
          if (element.classList.contains("wx-table-wrapper")) {
            const style = window.getComputedStyle(element);
            const width = style.width;

            const wrapperClass = Array.from(element.classList).find((cls) =>
              cls.startsWith("x2-")
            );
            if (wrapperClass) {
              positions[`wrapper-${wrapperClass}`] = width;
              saveResizerPositions(positions);
            }
          }
        }
      });
    });

    // 監視対象要素を設定
    const startObserving = () => {
      // リサイザーの監視
      const resizers = document.querySelectorAll(".wx-resizer-x");
      resizers.forEach((resizer) => {
        observer.observe(resizer, {
          attributes: true,
          attributeFilter: ["style"],
        });
      });

      // テーブルラッパーの監視
      const wrappers = document.querySelectorAll(".wx-table-wrapper");
      wrappers.forEach((wrapper) => {
        observer.observe(wrapper, {
          attributes: true,
          attributeFilter: ["style"],
        });
      });
    };

    // DOMが読み込まれた後に監視を開始
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", startObserving);
    } else {
      startObserving();
    }
  };

  // 監視を開始
  observeResizers();

  return {
    // 保存された位置を復元
    restore: () => {
      // リサイザーの位置を復元
      const resizers = document.querySelectorAll(".wx-resizer-x");
      resizers.forEach((resizer) => {
        const resizerClass = Array.from(resizer.classList).find((cls) =>
          cls.startsWith("x2-")
        );
        if (resizerClass && positions[`resizer-${resizerClass}`]) {
          resizer.style.left = positions[`resizer-${resizerClass}`];
        }
      });

      // テーブルラッパーの幅を復元
      const wrappers = document.querySelectorAll(".wx-table-wrapper");
      wrappers.forEach((wrapper) => {
        const wrapperClass = Array.from(wrapper.classList).find((cls) =>
          cls.startsWith("x2-")
        );
        if (wrapperClass && positions[`wrapper-${wrapperClass}`]) {
          // wrapper.style.width = positions[`wrapper-${wrapperClass}`];
          // flex-basisを設定
          wrapper.style.flexBasis = positions[`wrapper-${wrapperClass}`];
        }
      });
    },

    // 監視を停止
    disconnect: () => {
      if (observer) {
        observer.disconnect();
      }
    },
  };
};
