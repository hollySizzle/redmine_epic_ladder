// 日本の祝日判定ユーティリティ

/**
 * 指定された日付が日本の祝日かどうかを判定
 * @param {Date} date - 判定したい日付
 * @returns {boolean} - 祝日の場合true
 */
export const isJapaneseHoliday = (date) => {
  const year = date.getFullYear();
  const month = date.getMonth() + 1;
  const day = date.getDate();
  
  // 固定祝日
  const fixedHolidays = [
    [1, 1],   // 元日
    [2, 11],  // 建国記念の日
    [2, 23],  // 天皇誕生日
    [4, 29],  // 昭和の日
    [5, 3],   // 憲法記念日
    [5, 4],   // みどりの日
    [5, 5],   // こどもの日
    [8, 11],  // 山の日
    [11, 3],  // 文化の日
    [11, 23], // 勤労感謝の日
    [12, 23]  // 天皇誕生日（2019年以降）
  ];
  
  // 固定祝日チェック
  for (const [holidayMonth, holidayDay] of fixedHolidays) {
    if (month === holidayMonth && day === holidayDay) {
      // 天皇誕生日の年度による調整
      if (month === 12 && day === 23 && year < 2019) continue;
      if (month === 2 && day === 23 && year < 2020) continue;
      return true;
    }
  }
  
  // 移動祝日（ハッピーマンデー等）
  const weekday = date.getDay(); // 0:日曜 1:月曜 ... 6:土曜
  const nthWeekday = Math.ceil(day / 7);
  
  // 1月第2月曜日：成人の日
  if (month === 1 && weekday === 1 && nthWeekday === 2) return true;
  
  // 7月第3月曜日：海の日
  if (month === 7 && weekday === 1 && nthWeekday === 3) return true;
  
  // 9月第3月曜日：敬老の日
  if (month === 9 && weekday === 1 && nthWeekday === 3) return true;
  
  // 10月第2月曜日：スポーツの日（体育の日）
  if (month === 10 && weekday === 1 && nthWeekday === 2) return true;
  
  // 春分の日・秋分の日の近似計算
  if (month === 3) {
    const vernalEquinox = Math.floor(20.8431 + 0.242194 * (year - 1851) - Math.floor((year - 1851) / 4));
    if (day === vernalEquinox) return true;
  }
  
  if (month === 9) {
    const autumnalEquinox = Math.floor(23.2488 + 0.242194 * (year - 1851) - Math.floor((year - 1851) / 4));
    if (day === autumnalEquinox) return true;
  }
  
  return false;
};

/**
 * 指定された日付が土曜日かどうかを判定
 * @param {Date} date - 判定したい日付
 * @returns {boolean} - 土曜日の場合true
 */
export const isSaturday = (date) => {
  return date.getDay() === 6;
};

/**
 * 指定された日付が日曜日かどうかを判定
 * @param {Date} date - 判定したい日付
 * @returns {boolean} - 日曜日の場合true
 */
export const isSunday = (date) => {
  return date.getDay() === 0;
};

/**
 * 指定された日付が土日かどうかを判定
 * @param {Date} date - 判定したい日付
 * @returns {boolean} - 土日の場合true
 */
export const isWeekend = (date) => {
  return isSaturday(date) || isSunday(date);
};