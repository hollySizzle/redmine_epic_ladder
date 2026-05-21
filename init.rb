# plugins/redmine_react_gantt_chart/init.rb
Redmine::Plugin.register :redmine_react_gantt_chart do
  name 'Redmine React Gantt Chart plugin'
  author 'HollySizzle'
  description 'React-based Gantt chart plugin using SVAR Gantt'
  version '1.0.0'
  url 'http://example.com/path'
  author_url 'http://example.com/about'

  project_module :react_gantt_chart do
    permission :view_react_gantt_chart, {
      react_gantt_chart: [:index, :data, :filters, :bulk_update, :create_subtask]
    }, require: :member
    permission :manage_react_gantt_chart, {
      react_gantt_chart: [:bulk_update, :create_subtask]
    }, require: :member
  end

  menu :project_menu,
       :react_gantt_chart,
       { controller: 'react_gantt_chart', action: 'index' },
       caption: 'ReactGantt',
       param: :project_id
end
