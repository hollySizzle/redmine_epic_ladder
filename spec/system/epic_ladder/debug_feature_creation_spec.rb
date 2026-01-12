# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

RSpec.describe 'Debug Feature Creation', type: :system, js: true do
  let!(:project) { setup_epic_ladder_project(identifier: 'debug-test', name: 'Debug Test') }
  let!(:user) { setup_admin_user(login: 'debug_user') }

  before(:each) do
    epic_tracker = project.trackers.find { |t| t.name == EpicLadderTestConfig::TRACKER_NAMES[:epic] }
    @epic1 = create(:issue, project: project, tracker: epic_tracker, subject: 'Test Epic')
  end

  it 'debugs Feature creation step by step' do
    login_as(user)
    goto_kanban(project)

    puts "\n=== Step 1: Find Add Feature button ==="
    button_selector = ".epic-cell[data-epic='#{@epic1.id}'] button[data-add-button='feature']"
    button = @playwright_page.wait_for_selector(button_selector, state: 'visible', timeout: 15000)
    puts "✅ Button found: #{button_selector}"

    puts "\n=== Step 2: Click button ==="
    button.click
    puts "✅ Button clicked"

    puts "\n=== Step 3: Wait for modal ==="
    # Headless UI Dialog内の実際のセレクタを使用
    input_selector = 'input#issue-subject'
    @playwright_page.wait_for_selector(input_selector, state: 'attached', timeout: 10000)
    puts "✅ Modal input attached"

    @playwright_page.wait_for_function("() => document.querySelector('#{input_selector}').offsetParent !== null", timeout: 5000)
    puts "✅ Modal input visible"

    puts "\n=== Step 4: Fill form ==="
    @playwright_page.fill(input_selector, 'Debug Feature')
    puts "✅ Form filled"

    sleep 1
    puts "Input value: #{@playwright_page.evaluate("document.querySelector('#{input_selector}').value")}"

    puts "\n=== Step 5: Check submit button ==="
    submit_selector = '.modal-actions button[type="submit"]'
    submit_button = @playwright_page.query_selector(submit_selector)
    puts "Submit button found: #{!submit_button.nil?}"
    if submit_button
      puts "Submit button disabled: #{submit_button.evaluate('el => el.disabled')}"
      puts "Submit button text: #{submit_button.text_content}"
    end

    puts "\n=== Step 6: Capture console errors ==="
    console_messages = []
    @playwright_page.on('console', ->(msg) {
      console_messages << "[#{msg.type}] #{msg.text}"
      puts "[CONSOLE #{msg.type.upcase}] #{msg.text}"
    })

    puts "\n=== Step 7: Submit ==="
    @playwright_page.click(submit_selector)
    puts "✅ Submit clicked"

    puts "\n=== Step 8: Wait and check ==="
    sleep 3
    modal_still_open = @playwright_page.evaluate("() => !!document.querySelector('#{input_selector}')")
    puts "Modal still open: #{modal_still_open}"
    puts "Console messages count: #{console_messages.length}"

    puts "\n=== Step 9: Check for Feature ==="
    features = @playwright_page.query_selector_all('.feature-cell')
    puts "Feature cells found: #{features.length}"
    features.each_with_index do |f, i|
      puts "  Feature #{i}: #{f.text_content.strip}"
    end

    # Check feature_order_by_epic specifically
    feature_order = @playwright_page.evaluate("() => {
      const state = window.useStore?.getState ? window.useStore.getState() : null;
      if (!state) return 'Store not accessible';
      return state.grid.feature_order_by_epic;
    }")
    puts "feature_order_by_epic: #{feature_order.inspect}"

    puts "\n=== Step 10: Check store state ==="
    store_state = @playwright_page.evaluate("() => {
      const state = window.__ZUSTAND_STORE__;
      if (!state) return 'Store not found';
      const store = state.getState ? state.getState() : state;
      return {
        featuresCount: Object.keys(store.entities?.features || {}).length,
        error: store.error,
        projectId: store.projectId
      };
    }")
    puts "Store state: #{store_state}"

    puts "\n=== Step 11: Check for errors in console ==="
    all_text = @playwright_page.evaluate("() => document.body.textContent")
    puts "Page contains 'Error': #{all_text.include?('Error')}"
    puts "Page contains 'Debug Feature': #{all_text.include?('Debug Feature')}"
  end
end
