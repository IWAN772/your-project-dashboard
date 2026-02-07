# Web Dashboard

The web dashboard provides a visual interface for browsing, filtering, and managing your scanned projects. Start it with:

```bash
bin/dev
```

Then open [http://localhost:3000](http://localhost:3000).

## Dashboard overview

The main page has three sections:

### Quick Resume cards

The top of the page shows up to 12 cards for your most recently active projects (excluding forks). Each card displays:

- Project name
- Status badge (Active, Recent, WIP, Deployed, Paused)
- Description excerpt
- Last commit date (relative, e.g. "3 days ago")
- Tech stack badges
- Project type

These give you a fast way to jump back into whatever you were working on.

### Left rail navigation

The left sidebar provides quick access to:

- **Pinned projects** -- projects you've manually pinned for easy access (up to 15)
- **Recently viewed** -- the last 10 projects you've opened in the dashboard
- **Smart groups**:
  - *Active this week* -- projects with commits in the last 7 days
  - *Stalled* -- projects last committed to 14-60 days ago

Clicking a smart group filters the main project list accordingly.

### Project list

Below the Quick Resume cards is a paginated table (25 per page) showing all projects with:

- Project name (links to detail page)
- Status badge
- Last activity date (relative)

## Filtering and search

A filter bar sits between the Quick Resume cards and the project list. You can combine any of these:

| Filter | Options |
|--------|---------|
| **Search** | Free-text search across project name, path, last commit message, and description |
| **Ownership** | All Projects, Your Projects, Forks |
| **Status** | All, Active, Recent, Paused, WIP, Deployed |
| **Tech Stack** | Dynamically populated from your projects (Ruby, Rails, Node, Python, etc.) |
| **Project Type** | Dynamically populated (rails-app, node-app, python-app, etc.) |

### Sorting

The project list can be sorted by:
- **Name** (ascending/descending)
- **Last commit date** (default, newest first)
- **Commit count** (most active first)

## Project detail page

Click any project to see its full detail page. This includes:

### Metadata
- Full path on disk
- GitHub link (if the remote points to GitHub)
- Tech stack badges
- Project type
- Last commit date, message, and author
- Deployment status indicators
- Documentation file inventory (grouped by root, `.ai/`, `.cursor/`, `tasks/`, `docs/`)

### Quick actions
- **Pin/Unpin** -- toggle the project's pinned status for left rail access
- **Open on GitHub** -- direct link to the repository (when available)

### Tags

Add custom tags to organize projects. Tags are normalized (lowercased, trimmed) and shared across projects. Use them for anything -- client names, priorities, topics.

- Type a tag name and press Enter or click Add to create it
- Click the X on a tag to remove it from the project
- Tags are visible on the project detail page

### Notes

Add timestamped notes to any project. Notes are ordered newest-first and useful for recording context, decisions, or status updates.

- Type your note and submit to add it
- Click delete to remove a note
- Notes are rendered inline on the project detail page

### Goals

Track goals associated with a project. Each goal has a status:

| Status | Meaning |
|--------|---------|
| `not_started` | Goal is defined but work hasn't begun |
| `in_progress` | Currently being worked on |
| `completed` | Done |

Goals are shared entities -- the same goal can be associated with multiple projects, each with its own status. This is useful for cross-cutting objectives like "migrate to Rails 8" that span several repos.

- Add a goal by name (creates it if new, or links the existing one)
- Update its status with the dropdown
- Remove the association to unlink a goal from a project

### Navigation

Previous/Next links at the top of the detail page let you step through projects sequentially by database ID.

## Technical notes

The dashboard is built with:
- **Hotwire (Turbo + Stimulus)** -- filters update without full page reloads via Turbo Streams
- **Tailwind 4** -- utility-first CSS styling
- **Kaminari** -- pagination with a Tailwind-compatible theme
- **Solid Cache** -- tech stack and project type filter options are cached for 1 hour to avoid repeated queries
