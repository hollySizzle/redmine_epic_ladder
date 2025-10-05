# frozen_string_literal: true

# DEPRECATED: このファイルは epic_grid_e2e_helpers.rb に置き換えられました
# Playwrightベースの新しいヘルパーを使用してください

# module SystemTestHelper
#   def login_as(user, password: 'password123')
#     visit '/login'
#     fill_in 'username', with: user.login
#     fill_in 'password', with: password
#     click_button 'Login'
#   end
# end
#
# RSpec.configure do |config|
#   config.include SystemTestHelper, type: :system
# end