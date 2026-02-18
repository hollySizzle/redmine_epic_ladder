# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-02-18

### Added

- Epic Ladder view: kanban-style React/TypeScript UI for visualizing Epic/Feature/UserStory hierarchy across versions
- Tracker hierarchy enforcement (Epic > Feature > UserStory > Task/Bug/Test) with configurable tracker mapping
- VersionDateManager: automatic start/due date calculation when assigning issues to versions
- Drag-and-drop support for moving issues between versions and reordering within the board
- Side panel with search, list, and about tabs for issue navigation
- Detail pane for inline issue viewing within the Epic Ladder board
- Filter panel for narrowing displayed issues by various criteria
- MCP (Model Context Protocol) server integration for AI agent collaboration
  - Issue CRUD tools: create/update Epic, Feature, UserStory, Task, Bug, Test
  - Version management tools: create version, assign to version, move to next version
  - Query tools: list epics, list user stories, list versions, list project members, list statuses
  - Issue detail and project structure visualization tools
  - Issue field update tools: status, assignee, description, subject, parent, progress, custom fields
  - Per-tool hint configuration for guiding AI agent behavior
- Issue detail view hooks: quick actions for version changes, hierarchy navigation, and child issue creation
- Project-level settings for enabling/disabling plugin features per project
- Plugin-level settings for global tracker name mapping and MCP API toggle
- Automatic asset deployment (npm-free environment support)
- Internationalization support (English and Japanese locales)
- RSpec test suite for controllers, models, MCP tools, and hooks
- Vitest test suite for React frontend components
- MSW (Mock Service Worker) integration for frontend API mocking and contract testing
