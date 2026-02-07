# Getting Started

## Requirements

- **Ruby 3.4+**
- **SQLite3**
- **Git** (available in your PATH)

## Installation

Clone the repository and run the setup script:

```bash
git clone <repo-url> your-project-dashboard
cd your-project-dashboard
bin/setup
bin/rails db:migrate
```

`bin/setup` installs gem dependencies, creates the database, and prepares the asset pipeline.

## Scan your projects

Run the scanner to discover all git repositories under your development directory:

```bash
bin/rake projects:scan
```

By default this scans `~/Development` and finds repositories with commits in the last 8 months. You'll see live progress as each repo is discovered and analyzed:

```
Scanning for git repositories in /Users/you/Development...
  ✓ Found repo: my-rails-app                   (1 total)
  ✓ Found repo: side-project                   (2 total)
  ...

Processing projects...
  [1/42] my-rails-app                            ✓ [Own]  rails-app    (2026-02-05)
  [2/42] side-project                            ✓ [Own]  node-app     (2026-01-20)
```

To preview without saving to the database:

```bash
DRY_RUN=true bin/rake projects:scan
```

See [Scanning](SCANNING.md) for all configuration options.

## Launch the dashboard

Start the development server:

```bash
bin/dev
```

Then open [http://localhost:3000](http://localhost:3000) in your browser. You'll see the dashboard with all your scanned projects, Quick Resume cards for recently active work, and filtering tools.

`bin/dev` starts both the Rails server and the Tailwind CSS watcher. If you only need the server:

```bash
bin/rails server
```

## Next steps

- **[Scanning](SCANNING.md)** -- Configure scan paths, cutoff dates, and understand what metadata gets extracted.
- **[Web Dashboard](WEB_DASHBOARD.md)** -- Learn about filtering, search, tags, notes, goals, and pinned projects.
- **[Architecture](ARCHITECTURE.md)** -- Understand the codebase structure and how to extend it.
