# plugins/redmine_react_gantt_chart/config/routes.rb
RedmineApp::Application.routes.draw do
  resources :projects do
    get 'react_gantt_chart', to: 'react_gantt_chart#index'
    get 'react_gantt_chart/data', to: 'react_gantt_chart#data'
    get 'react_gantt_chart/filters', to: 'react_gantt_chart#filters'
    post 'react_gantt_chart/bulk_update', to: 'react_gantt_chart#bulk_update'
    post 'react_gantt_chart/create_subtask', to: 'react_gantt_chart#create_subtask'
    get 'react_gantt_chart/task/:task_id/status', to: 'react_gantt_chart#task_status'
  end
end
