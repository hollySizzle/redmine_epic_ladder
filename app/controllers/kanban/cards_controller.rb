# app/controllers/kanban/cards_controller.rb
class Kanban::CardsController < ApplicationController
  include KanbanApiConcern

  def index
    @kanban_data = Kanban::KanbanDataBuilder.new(@project, current_user, filter_params).build

    render json: {
      epics: serialize_epics(@kanban_data[:epics]),
      columns: @kanban_data[:columns],
      metadata: {
        project: project_metadata,
        user: user_metadata,
        permissions: user_permissions
      }
    }
  end

  private

  def serialize_epics(epics)
    epics.map do |epic|
      {
        issue: serialize_issue(epic),
        features: serialize_features(epic.features)
      }
    end
  end

  def serialize_features(features)
    features.map do |feature|
      {
        issue: serialize_issue(feature),
        user_stories: serialize_user_stories(feature.user_stories)
      }
    end
  end

  def serialize_user_stories(user_stories)
    user_stories.map do |user_story|
      {
        issue: serialize_issue(user_story),
        tasks: user_story.tasks.map { |task| serialize_issue(task) },
        tests: user_story.tests.map { |test| serialize_issue(test) },
        bugs: user_story.bugs.map { |bug| serialize_issue(bug) }
      }
    end
  end

  def filter_params
    params.permit(:version_id, :assignee_id, :status_id)
  end
end