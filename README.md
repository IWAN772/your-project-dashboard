# Your Project Dashboard

A Rails 8.2 application that automatically discovers, analyzes, and tracks all active git repositories in your local development environment.

**Problem:** When you're juggling dozens of active projects across multiple directories, it's hard to remember what exists, what's active, and where things are.

**Solution:** Automated project discovery and intelligent metadata extraction. One command gives you a complete inventory of your development work, with a web dashboard to browse and manage it all.

## Features

- **Automatic git repository discovery** — recursively scans your development directories
- **Rich metadata extraction** — tech stack, commit history, contributors, deployment status
- **Web dashboard** — browse projects with filtering, search, and sorting
- **Quick Resume cards** — jump back into recently active projects
- **Left rail navigation** — pinned projects, recent activity, smart groups
- **Project detail pages** — full metadata, goals, notes, and tags per project

## Requirements

- Ruby 3.4+
- SQLite3

## Setup

```bash
bin/setup
bin/rails db:migrate
```

## Usage

### Scan your projects

```bash
bin/rake projects:scan                              # Full scan and save
DRY_RUN=true bin/rake projects:scan                 # Preview without saving
SCAN_ROOT_PATH=~/code bin/rake projects:scan        # Custom directory
SCAN_CUTOFF_DAYS=180 bin/rake projects:scan         # 6 months instead of 8
bin/rake projects:config                            # Show configuration
```

### Start the web dashboard

```bash
bin/dev
```

Then visit [http://localhost:3000](http://localhost:3000).

### Query from the console

```bash
bin/rails console
```

```ruby
# All projects, most recent first
Project.order(last_commit_date: :desc)

# Rails projects only
Project.where("metadata ->> 'inferred_type' = ?", "rails-app")

# Count by type
Project.all.group_by { |p| p.metadata['inferred_type'] }.transform_values(&:count)

# Most active by commit count
Project.all.sort_by { |p| p.metadata['commit_count_8m'] || 0 }.reverse.first(10)
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `SCAN_ROOT_PATH` | `~/Development` | Root directory to scan |
| `SCAN_CUTOFF_DAYS` | `240` (8 months) | Projects older than this are skipped |
| `DRY_RUN` | `false` | If `true`, scan but don't save |

## Architecture

```
Rake Task → ProjectScanner → ProjectData → Project Model → SQLite
```

- **ProjectScanner** (`lib/project_scanner.rb`) — discovers repos, orchestrates scanning
- **ProjectData** (`lib/project_data.rb`) — extracts metadata via git commands and file analysis
- **Project** (`app/models/project.rb`) — ActiveRecord model with JSON metadata column

The `metadata` JSON column stores tech stack, commit history, contributors, deployment status, documentation inventory, and more — no migrations needed when adding new fields.

## Tech Stack

- **Ruby 3.4** / **Rails 8.2**
- **SQLite3** — local-first, no external dependencies
- **Tailwind 4** + **Hotwire** (Turbo + Stimulus) — web UI
- **Propshaft** + **Importmap** — asset pipeline
- **Solid Queue** / **Solid Cache** — background jobs and caching

## License

MIT
