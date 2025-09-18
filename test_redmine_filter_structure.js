// Redmineのフィルター構造を模擬するテストスクリプト
// 実際のRedmineがどのような構造を返すかを確認

console.log('=== Redmineフィルター構造テスト ===');

// 想定されるRedmineのavailable_filtersの構造
const expectedRedmineFilters = {
  tracker_id: {
    name: "トラッカー",
    type: "list_optional", // または "list"
    values: [
      ["開発", "1"],
      ["バグ", "2"], 
      ["運用", "3"],
      ["保守", "4"]
    ]
  },
  status_id: {
    name: "ステータス",
    type: "list_optional",
    values: [
      ["提案", "1"],
      ["未着手", "2"],
      ["着手中", "3"],
      ["レビュー", "4"],
      ["完了", "5"]
    ]
  },
  assigned_to_id: {
    name: "担当者",
    type: "list_optional",
    values: [
      ["山田太郎", "1"],
      ["田中花子", "2"]
    ]
  }
};

// 想定されるoperatorByTypeの構造  
const expectedOperatorByType = {
  "list": ["=", "!"],
  "list_optional": ["=", "!", "!*", "*"],
  "string": ["~", "!~", "=", "!"],
  "date": ["=", ">=", "<=", "><", "t", "w", "y"]
};

console.log('expected tracker_id:', expectedRedmineFilters.tracker_id);
console.log('expected operator for list_optional:', expectedOperatorByType.list_optional);

// フィールドタイプ判定ロジックのテスト
function testFieldTypeLogic(fieldType) {
  console.log(`\nテスト: fieldType="${fieldType}"`);
  console.log(`  startsWith('list'): ${fieldType.startsWith('list')}`);
  console.log(`  === 'list': ${fieldType === 'list'}`);
  console.log(`  === 'list_optional': ${fieldType === 'list_optional'}`);
}

testFieldTypeLogic('list');
testFieldTypeLogic('list_optional');
testFieldTypeLogic('string');
testFieldTypeLogic('date');

// 値の配列構造テスト
function testValuesStructure(values) {
  console.log('\n値の構造テスト:');
  console.log('values:', values);
  console.log('values.length:', values.length);
  console.log('first item:', values[0]);
  console.log('first item type:', typeof values[0]);
  console.log('is array:', Array.isArray(values[0]));
  
  if (Array.isArray(values[0])) {
    console.log('first item structure: [label, value]');
    console.log('  label:', values[0][0]);
    console.log('  value:', values[0][1]);
    console.log('  value type:', typeof values[0][1]);
  }
}

testValuesStructure(expectedRedmineFilters.tracker_id.values);

console.log('\n=== 予想される問題 ===');
console.log('1. フィルターAPI が期待通りのデータを返していない');
console.log('2. フィールドタイプの判定ロジックが正しく動作していない'); 
console.log('3. 値の配列構造が期待と異なる');
console.log('4. JavaScriptとRubyの間でデータ形式が変換されている');