# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

# Playwright環境でprompt()が動作するか確認するテスト
RSpec.describe 'Prompt Test', type: :system, js: true do
  let!(:project) { setup_epic_grid_project(identifier: 'prompt-test', name: 'Prompt Test') }
  let!(:user) { setup_admin_user(login: 'prompt_tester') }

  def handle_test_dialog(dialog)
    puts "✅ Dialog detected: #{dialog.type} - #{dialog.message}"
    dialog.accept('Test Input From Method')
  end

  it 'tests if prompt() works in Playwright environment' do
    login_as(user)
    goto_kanban(project)

    puts "\n=== Testing prompt() in Playwright ==="

    # テスト1: evaluate経由でprompt()を直接呼び出し（method形式）
    puts "\n[Test 1] Calling prompt() via evaluate with method handler..."
    @playwright_page.on('dialog', method(:handle_test_dialog))

    begin
      result = @playwright_page.evaluate("() => prompt('Enter something:')")
      puts "✅ Result from evaluate: #{result.inspect}"
    rescue => e
      puts "❌ Error in evaluate: #{e.message}"
    end

    sleep 1

    # テスト2: ページ内のボタンからprompt()を呼び出し
    puts "\n[Test 2] Injecting button that calls prompt()..."
    @playwright_page.evaluate(<<~JS)
      const btn = document.createElement('button');
      btn.id = 'test-prompt-btn';
      btn.textContent = 'Test Prompt';
      btn.onclick = () => {
        console.log('Button clicked, calling prompt...');
        const result = prompt('Test prompt from button');
        console.log('Prompt result:', result);
      };
      document.body.appendChild(btn);
    JS

    test_button = @playwright_page.wait_for_selector('#test-prompt-btn', state: 'visible', timeout: 5000)
    puts "✅ Test button created"

    test_button.click
    puts "✅ Test button clicked"

    sleep 2

    puts "\n=== Prompt Test Complete ==="
  end
end
