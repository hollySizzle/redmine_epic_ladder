# Project Overview: redmine_epic_ladder

## Purpose
Redmine plugin providing kanban-style Epic Ladder UI, tracker hierarchy enforcement (Epic>Feature>UserStory>Task/Bug/Test), and AI agent integration via MCP.

## Tech Stack
- Backend: Ruby (Redmine plugin), RSpec tests
- Frontend: React/TypeScript, Vitest tests, Webpack build
- MCP: Model Context Protocol server for AI agent collaboration

## Key Directories
- `app/controllers/epic_ladder/` - API endpoints
- `app/models/epic_ladder/` - VersionDateManager, TrackerHierarchy, etc.
- `lib/epic_ladder/mcp_tools/` - MCP tool implementations
- `lib/epic_ladder/hooks/` - Redmine view hooks
- `assets/javascripts/epic_ladder/src/` - React/TypeScript frontend
- `spec/` - RSpec tests
- `vibes/` - Documentation and scripts

## Commands
- Backend tests: `RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/`
- Frontend tests: `cd assets/javascripts/epic_ladder && npm test`
- Version: 1.0.0 (defined in init.rb)

## Git Notes
- The `.git` file may reference a broken submodule path. Reinitialize with `git init` if needed.
- Add safe.directory: `git config --global --add safe.directory /usr/src/redmine/plugins/redmine_epic_ladder`
