# Scanning

The scanner discovers git repositories in your development directories, extracts rich metadata from each one, and saves the results to a local SQLite database.

## Running a scan

```bash
bin/rake projects:scan
```

This will:
1. Recursively find all `.git` directories under the root path
2. Filter out repositories with no commits in the cutoff window
3. Extract metadata from each qualifying repository
4. Upsert results into the database (matched by path)

## Configuration

All configuration is done through environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `SCAN_ROOT_PATH` | `~/Development` | Root directory to scan |
| `SCAN_CUTOFF_DAYS` | `240` (8 months) | Repositories with no commits newer than this are skipped |
| `DRY_RUN` | `false` | Set to `"true"` to scan without saving to the database |

Examples:

```bash
# Scan a different directory
SCAN_ROOT_PATH=~/code bin/rake projects:scan

# Only include projects active in the last 3 months
SCAN_CUTOFF_DAYS=90 bin/rake projects:scan

# Preview what would be found without writing to the database
DRY_RUN=true bin/rake projects:scan

# Show current configuration
bin/rake projects:config
```

## What gets extracted

For every qualifying repository, the scanner collects:

### Git metadata
- **Last commit** -- date, message, and author
- **Recent commits** -- the 10 most recent commits (date + message)
- **Commit count** -- total commits in the last 8 months
- **Contributors** -- all unique commit authors
- **Remote URL** -- the `origin` remote, used to generate GitHub links

### Tech stack detection

The scanner checks for signature files to identify technologies:

| Technology | Detected by |
|------------|-------------|
| Ruby | `Gemfile` |
| Rails | `Gemfile` containing `rails`, or `config/routes.rb` |
| Node.js | `package.json` |
| React | `package.json` containing `react` |
| Next.js | `package.json` containing `next` |
| Vue | `package.json` containing `vue` |
| Python | `requirements.txt` or `pyproject.toml` |
| Go | `go.mod` |

### Project type inference

Based on detected tech stack:

| Type | Condition |
|------|-----------|
| `rails-app` | Rails detected |
| `node-app` | Node.js detected (no Rails) |
| `python-app` | Python detected |
| `docs` | Has files in a `docs/` directory |
| `script` | Has `.rb` or `.js` files in the project root |
| `unknown` | None of the above |

### Deployment status

The scanner looks for deployment indicators:
- `bin/deploy` script
- `"deploy"` or `"build"` scripts in `package.json`
- `Dockerfile`, `docker-compose.yml`, `Procfile`
- Mentions of "deploy", "production", "live", or "hosting" in `README.md`

### Documentation inventory

Reference files are organized by location:

| Category | Files checked |
|----------|--------------|
| Root | `README.md`, `CLAUDE.md`, `AGENT.md`, `CHANGELOG.md` |
| AI | Markdown files in `.ai/` |
| Cursor | Markdown files in `.cursor/` |
| Tasks | Markdown files in `tasks/` |
| Docs | Markdown files in `docs/` |

### Project state

Current state is inferred from a combination of signals:
- **TODO tracking** -- counts open (`- [ ]`) and completed (`- [x]`) tasks from `TODO.md` files (checked in `.ai/`, `.cursor/`, and root)
- **Commit message keywords** -- detects WIP, TODO, FIXME, "in progress", "done", "complete", "finish", "ship"
- **Commit recency** -- "active" (< 7 days), "recently active" (< 30 days), or "paused" (30+ days)

### Ownership

The scanner detects whether a repository is your own project or a fork by checking the git remote URL.

## How directories are traversed

The scanner uses Ruby's `Find` module to walk the directory tree. It applies several pruning rules for performance:

- **Hidden directories** (starting with `.`) are skipped, except `.git` is used to identify repositories
- **`node_modules`** directories are always skipped
- **Nested repositories** -- once a `.git` directory is found, the scanner does not descend further into that project
- **Progress feedback** -- directory counts and repo discoveries are printed in real time

## Standalone indexer

There is also a standalone script at `bin/index_all_projects` that indexes projects without requiring git history or a date cutoff. It detects projects by the presence of build files (`Gemfile`, `package.json`, `Cargo.toml`, etc.) and outputs a JSON file.

```bash
bin/index_all_projects                       # Scan ~/Development, write project_index.json
bin/index_all_projects ~/code output.json    # Custom root and output file
```

This supports a broader range of project types (Rust, Elixir, Java, C/C++, Docker) and searches up to 4 levels deep.

## Re-scanning

Running the scanner again will update existing records. Projects are matched by their filesystem path, so re-scanning is safe to run repeatedly -- it updates metadata for known projects and adds any newly discovered ones.

Projects that have been removed from disk or fallen outside the cutoff window are not automatically deleted from the database.
