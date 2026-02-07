# Architecture

## Data flow

```
bin/rake projects:scan
        │
        ▼
┌─────────────────┐
│ ProjectScanner  │  Finds .git directories, filters by recency
│ lib/            │  Orchestrates scanning loop and DB persistence
└────────┬────────┘
         │  For each repo
         ▼
┌─────────────────┐
│  ProjectData    │  Extracts git metadata, tech stack, docs,
│  lib/           │  deployment status, current state
└────────┬────────┘
         │  Structured hash
         ▼
┌─────────────────┐
│  Project model  │  ActiveRecord, upserts by path
│  app/models/    │  JSON metadata column
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  SQLite DB      │  storage/development.sqlite3
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Web Dashboard  │  Rails controllers + Hotwire views
│  app/           │  Filtering, search, detail pages
└─────────────────┘
```

## Key components

### ProjectScanner (`lib/project_scanner.rb`)

Responsible for discovering repositories and orchestrating the scan process.

- Uses Ruby's `Find` module for recursive directory traversal
- Prunes hidden directories, `node_modules`, and already-processed repository subtrees
- Shows real-time progress output (directory counts, repo discoveries)
- Collects results into `@projects` (valid, within cutoff) and `@skipped_projects`
- `save_to_database` calls `Project.create_or_update_from_data` for each result
- `print_summary` outputs a breakdown by type, ownership, and recency

### ProjectData (`lib/project_data.rb`)

Plain Ruby class (no Rails dependencies) that extracts all metadata for a single repository.

- **Git data**: runs shell commands (`git log`, `git rev-list`, `git config`) via backticks, capturing stderr to `/dev/null`
- **Tech stack**: checks for signature files (`Gemfile`, `package.json`, `go.mod`, etc.)
- **Description**: searches a priority-ordered list of files (`.ai/PROJECT_STATUS.md`, `CLAUDE.md`, `README.md`, etc.) and extracts the first meaningful paragraph
- **Current state**: combines TODO file parsing, commit message keywords, and commit recency
- **Deployment status**: looks for deploy scripts, Dockerfiles, and deployment-related keywords in README
- **Reference files**: inventories documentation files across multiple conventional locations
- **Error handling**: per-extraction-step try/catch; errors are collected in `metadata[:errors]` rather than aborting

Design choice: ProjectData has no ActiveRecord dependency. This makes it testable in isolation and keeps extraction logic separate from persistence.

### Project model (`app/models/project.rb`)

ActiveRecord model backed by SQLite.

- **Upsert logic**: `create_or_update_from_data` finds or initializes by path, then updates all fields
- **Scopes**: `search`, `by_status`, `by_tech_stack`, `by_type`, `own_projects`, `forks`, `pinned`, `recently_viewed`, `active_this_week`, `stalled`
- **Helper methods**: `status`, `relative_last_commit_date`, `tech_stack_array`, `github_url`, `description`, `truncated_description`
- **Associations**: `tags` (through `taggings`), `notes`, `goals` (through `project_goals`)

### Filterable concern (`app/controllers/concerns/filterable.rb`)

Centralizes filter logic used by the projects controller:
- Search (free-text across name, path, commit message, description)
- Ownership (own vs forks)
- Status (active, recent, paused, WIP, deployed)
- Tech stack
- Project type
- Sorting (name, last commit date, commit count)

### Controllers

| Controller | Purpose |
|------------|---------|
| `ProjectsController` | Index (with filters, smart groups, pagination), show, toggle_pin |
| `NotesController` | Create and destroy notes (Turbo Stream responses) |
| `ProjectGoalsController` | Create, update status, and destroy goal associations |
| `TaggingsController` | Add and remove tags from projects |

## Database schema

```
projects
├── id (integer, PK)
├── path (string, unique index)
├── name (string)
├── last_commit_date (string, index)
├── last_commit_message (text)
├── metadata (json)
├── is_fork (boolean, index, default: false)
├── pinned (boolean, index, default: false)
├── last_viewed_at (datetime, index)
└── timestamps

tags
├── id (integer, PK)
├── name (string, unique index)
└── timestamps

taggings
├── id (integer, PK)
├── project_id (FK → projects, index)
├── tag_id (FK → tags, index)
├── unique index on [project_id, tag_id]
└── timestamps

notes
├── id (integer, PK)
├── project_id (FK → projects, index)
├── content (text)
├── index on [project_id, created_at]
└── timestamps

goals
├── id (integer, PK)
├── name (string, unique index)
├── description (text)
└── timestamps

project_goals
├── id (integer, PK)
├── project_id (FK → projects, index)
├── goal_id (FK → goals, index)
├── status (string, default: "not_started")
├── unique index on [project_id, goal_id]
└── timestamps
```

### The metadata JSON column

The `metadata` column on `projects` stores a flexible JSON object. This avoids migrations when adding new extracted fields. Key contents:

```json
{
  "last_commit_author": "name",
  "recent_commits": [{"date": "...", "message": "..."}],
  "commit_count_8m": 42,
  "contributors": ["author1", "author2"],
  "git_remote": "git@github.com:user/repo.git",
  "reference_files": {"root": ["README.md", "CLAUDE.md"], "ai": ["TODO.md"]},
  "description": "A short description of the project",
  "current_state": "active (committed 2 days ago), 3 open tasks",
  "tech_stack": ["ruby", "rails"],
  "inferred_type": "rails-app",
  "deployment_status": "likely deployed (has Dockerfile, has deploy script)",
  "nested_repos": [],
  "plans_count": 2,
  "ai_docs_count": 3,
  "claude_description": "Extracted from CLAUDE.md first paragraph",
  "errors": []
}
```

Query metadata in SQL using SQLite JSON operators:

```ruby
# By inferred type
Project.where("metadata ->> 'inferred_type' = ?", "rails-app")

# By tech stack (substring match on JSON array)
Project.where("json_extract(metadata, '$.tech_stack') LIKE ?", "%ruby%")

# By deployment status
Project.where("json_extract(metadata, '$.deployment_status') LIKE ?", "%likely deployed%")
```

## Tech stack

| Layer | Technology |
|-------|-----------|
| Language | Ruby 3.4+ |
| Framework | Rails 8.2 (main branch) |
| Database | SQLite3 |
| Frontend | Tailwind 4, Hotwire (Turbo + Stimulus) |
| Assets | Propshaft + Importmap |
| Pagination | Kaminari with Tailwind theme |
| Background jobs | Solid Queue (configured, not yet heavily used) |
| Caching | Solid Cache |
| Deployment | Kamal-ready (Dockerfile, Thruster) |

## Design decisions

**SQLite over Postgres/MySQL** -- This is a local-first tool. SQLite requires no server process, stores everything in a single file, and is fast for the expected data volume (< 10k projects).

**JSON metadata column** -- During active development, the set of extracted fields changes frequently. A JSON column lets new fields be added without migrations. SQLite's JSON operators provide adequate query performance.

**Shell git commands over git gems** -- `git` is universally available. Shell commands are fast for simple operations and avoid adding gem dependencies. ProjectData captures stderr to avoid noisy output.

**ProjectData as plain Ruby** -- Keeping extraction logic free of ActiveRecord dependencies makes it independently testable and potentially extractable as a standalone gem.

**Hotwire over a JS framework** -- Turbo Streams allow the filter bar to update the project list without a full page reload, while keeping the codebase server-rendered Ruby. No build step for JavaScript.

## Extending the scanner

### Adding a new metadata field

1. Add extraction logic in `ProjectData#extract_metadata`:

```ruby
def extract_metadata
  # ... existing fields ...
  @metadata[:my_new_field] = compute_new_field
end
```

2. No migration needed -- it's stored in the JSON column.

3. Access it via `project.metadata['my_new_field']` or add a helper method on the model.

### Adding a new tech stack

Update `ProjectData#detect_tech_stack`:

```ruby
def detect_tech_stack
  stack = []
  # ... existing checks ...
  stack << "rust" if File.exist?(File.join(@path, "Cargo.toml"))
  stack.uniq
end
```

Optionally update `infer_project_type` to handle the new category.

### Adding a new filter

1. Add a scope to `Project` model
2. Add the filter method in `Filterable` concern
3. Add UI controls in the view
