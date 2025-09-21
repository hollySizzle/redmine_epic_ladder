# app/controllers/kanban_controller.rb
class KanbanController < ApplicationController
  before_action :find_project, only: [:index]
  before_action :authorize

  def index
    # メインのKanbanビューを表示
    # app/views/kanban/index.html.erb でReactアプリを読み込む
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end

  def authorize
    deny_access unless User.current.allowed_to?(:view_kanban, @project)
  end
end