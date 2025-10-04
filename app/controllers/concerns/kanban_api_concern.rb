# app/controllers/concerns/kanban_api_concern.rb
module EpicGridApiConcern
  extend ActiveSupport::Concern

  included do
    before_action :require_login, :find_project, :authorize_kanban_access
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from StandardError, with: :render_internal_error
  end

  def serialize_issue(issue)
    {
      id: issue.id,
      subject: issue.subject,
      tracker: issue.tracker.name,
      status: issue.status.name,
      status_column: issue.current_kanban_column,
      assigned_to: issue.assigned_to&.name,
      fixed_version: issue.fixed_version&.name,
      version_source: issue.version_source,
      hierarchy_level: issue.hierarchy_level,
      can_release: issue.can_release?,
      blocked_by_relations: serialize_blocking_relations(issue)
    }
  end

  def serialize_blocking_relations(issue)
    issue.relations_to.where(relation_type: 'blocks').map do |relation|
      {
        id: relation.id,
        blocking_issue_id: relation.issue_from_id,
        blocking_issue_tracker: relation.issue_from.tracker.name
      }
    end
  end

  def project_metadata
    {
      id: @project.id,
      name: @project.name,
      trackers: @project.trackers.pluck(:id, :name),
      versions: @project.versions.pluck(:id, :name)
    }
  end

  def user_metadata
    {
      id: User.current.id,
      name: User.current.name
    }
  end

  def user_permissions
    {
      view_issues: User.current.allowed_to?(:view_issues, @project),
      edit_issues: User.current.allowed_to?(:edit_issues, @project),
      manage_versions: User.current.allowed_to?(:manage_versions, @project),
      view_kanban: User.current.allowed_to?(:view_kanban, @project),
      manage_kanban: User.current.allowed_to?(:manage_kanban, @project)
    }
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end

  def authorize_kanban_access
    deny_access unless User.current.allowed_to?(:view_kanban, @project)
  end

  def render_not_found(exception)
    render json: { error: 'リソースが見つかりません' }, status: :not_found
  end

  def render_internal_error(exception)
    Rails.logger.error "Kanban API Error: #{exception.message}"
    render json: { error: 'サーバーエラー', request_id: request.uuid }, status: :internal_server_error
  end
end