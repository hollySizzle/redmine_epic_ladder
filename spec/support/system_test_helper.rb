# frozen_string_literal: true

module SystemTestHelper
  def login_as(user, password: 'password123')
    visit '/login'
    fill_in 'username', with: user.login
    fill_in 'password', with: password
    click_button 'Login'
  end
end

RSpec.configure do |config|
  config.include SystemTestHelper, type: :system
end