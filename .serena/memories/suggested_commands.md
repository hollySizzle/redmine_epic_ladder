# Suggested Commands

## Testing
- Full RSpec: `RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/`
- MCP tools only: `RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/lib/epic_ladder/mcp_tools/`
- Controllers only: `RAILS_ENV=test bundle exec rspec plugins/redmine_epic_ladder/spec/controllers/`
- Frontend: `cd assets/javascripts/epic_ladder && npm test`

## Git
- May need: `git config --global --add safe.directory /usr/src/redmine/plugins/redmine_epic_ladder`
