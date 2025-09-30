# Gemfile for redmine_react_gantt_chart plugin

group :test do
  # 条件付き gem 定義: 既にインストールされている場合はスキップ
  begin
    Gem::Specification.find_by_name('rspec-rails')
  rescue Gem::LoadError
    gem 'rspec-rails', '~> 6.1'
  end

  begin
    Gem::Specification.find_by_name('factory_bot_rails')
  rescue Gem::LoadError
    gem 'factory_bot_rails', '~> 6.4'
  end

  begin
    Gem::Specification.find_by_name('faker')
  rescue Gem::LoadError
    gem 'faker', '~> 3.2'
  end

  begin
    Gem::Specification.find_by_name('database_cleaner-active_record')
  rescue Gem::LoadError
    gem 'database_cleaner-active_record', '~> 2.1'
  end

  begin
    Gem::Specification.find_by_name('simplecov')
  rescue Gem::LoadError
    gem 'simplecov', '~> 0.22', require: false
  end

  begin
    Gem::Specification.find_by_name('capybara')
  rescue Gem::LoadError
    gem 'capybara', '~> 3.40'
  end

  begin
    Gem::Specification.find_by_name('selenium-webdriver')
  rescue Gem::LoadError
    gem 'selenium-webdriver', '~> 4.15'
  end

  begin
    Gem::Specification.find_by_name('capybara-playwright-driver')
  rescue Gem::LoadError
    gem 'capybara-playwright-driver', '~> 0.5'
  end
end

group :development, :test do
  begin
    Gem::Specification.find_by_name('pry-rails')
  rescue Gem::LoadError
    gem 'pry-rails', '~> 0.3'
  end

  begin
    Gem::Specification.find_by_name('pry-byebug')
  rescue Gem::LoadError
    gem 'pry-byebug', '~> 3.10'
  end
end