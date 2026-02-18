# Epic Ladder Plugin - Project Onboarding

## Project Overview
- **Name**: redmine_epic_ladder
- **Version**: 1.0.0
- **Purpose**: Bring structure and modern UI to Redmine for PM efficiency
- **Architecture**: Ruby on Rails backend + React/TypeScript frontend

## Key Features
1. **Epic Ladder View** - React-based kanban with drag-and-drop
2. **Detail Screen Extensions** - Hooks for issue detail view
3. **MCP Tools** - 16 AI-powered tools for Claude integration

## Tech Stack
- **Backend**: Ruby on Rails, RSpec tests
- **Frontend**: React 18, TypeScript, Zustand, Vitest
- **Build**: Webpack, Babel, Tailwind CSS
- **Package**: npm (node_modules included in repo)

## Project Structure
```
app/
  controllers/epic_ladder/  # API endpoints
  models/epic_ladder/       # Business logic
  views/hooks/              # Detail screen extensions
lib/epic_ladder/
  mcp_tools/                # MCP tool implementations
  hooks/                    # Redmine hooks
assets/javascripts/epic_ladder/
  src/                      # React/TypeScript source
  build/                    # Production builds (git-managed)
spec/                       # RSpec tests
```

## Critical Files
- `CLAUDE.md` - Project configuration (provides design intent)
- `package.json` - Frontend dependencies & build scripts
- `README.md` - Deployment, MCP setup docs
- `app/models/epic_ladder/version_date_manager.rb` - Shared business logic
- `app/models/epic_ladder/tracker_hierarchy.rb` - Hierarchy rules

## Build Commands
- `npm run build` - Dev build (4.9MB, not committed)
- `npm run build:prod` - Production build (455KB with hash, committed to git)
- `npm run deploy` - Local deployment
- `npm run test` - Run Vitest suite
- `npm run dev` - Watch mode development

## Testing
- **Frontend**: `vitest` (JS/TS tests in spec/)
- **Backend**: `rspec` (Rails tests in spec/)
- **Full test**: `RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/`

## Design Constraints
- NO changes to Redmine core
- NO migrations (DB schema locked)
- TypeScript types are SSoT for API contracts
- Keep Changelog format: https://keepachangelog.com/ja/1.0.0/

## Tech-Lead Responsibility
- Peer review of CHANGELOG.md creation (T1)
- Validate Keep a Changelog format compliance
- Report findings to team lead with [tech-lead] markers
