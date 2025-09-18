# frozen_string_literal: true

require 'rspec/core/rake_task'

desc 'Run RSpec tests for the plugin'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'plugins/redmine_react_gantt_chart/spec/**/*_spec.rb'
  t.rspec_opts = '--color --format documentation'
end

namespace :redmine_react_gantt_chart do
  desc 'Run all tests'
  task :test => :spec
  
  desc 'Run performance tests only'
  task :test_performance do
    ENV['SPEC_OPTS'] = '--tag performance'
    Rake::Task['spec'].invoke
  end
  
  desc 'Run unit tests only'
  task :test_unit do
    ENV['SPEC_OPTS'] = '--tag ~performance'
    Rake::Task['spec'].invoke
  end
  
  desc 'Generate test coverage report'
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task['spec'].invoke
  end
end

# デフォルトタスク
task default: :spec