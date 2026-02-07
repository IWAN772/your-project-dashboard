class Project < ApplicationRecord
  validates :path, presence: true, uniqueness: true
  validates :name, presence: true
  validates :last_commit_date, presence: true

  # Scopes for filtering
  scope :search, ->(query) {
    where("name LIKE ? OR path LIKE ? OR last_commit_message LIKE ? OR json_extract(metadata, '$.description') LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
  }

  scope :by_status, ->(status) {
    case status
    when "active"
      # Use Ruby to calculate cutoff, extract date portion from stored string to avoid timezone issues
      cutoff_date = 7.days.ago.to_date
      where("date(substr(last_commit_date, 1, 10)) >= date(?)", cutoff_date)
    when "recent"
      cutoff_7_days = 7.days.ago.to_date
      cutoff_30_days = 30.days.ago.to_date
      where("date(substr(last_commit_date, 1, 10)) < date(?)", cutoff_7_days)
        .where("date(substr(last_commit_date, 1, 10)) >= date(?)", cutoff_30_days)
    when "paused"
      cutoff_date = 30.days.ago.to_date
      where("date(substr(last_commit_date, 1, 10)) < date(?)", cutoff_date)
    when "wip"
      where("last_commit_message LIKE ? OR json_extract(metadata, '$.current_state') LIKE ?",
            "%WIP%", "%work in progress%")
    when "deployed"
      where("json_extract(metadata, '$.deployment_status') LIKE ?", "%likely deployed%")
    else
      all
    end
  }

  scope :by_tech_stack, ->(tech) {
    where("json_extract(metadata, '$.tech_stack') LIKE ?", "%#{tech}%")
  }

  scope :by_type, ->(type) {
    where("json_extract(metadata, '$.inferred_type') = ?", type)
  }

  scope :own_projects, -> { where(is_fork: false) }
  scope :forks, -> { where(is_fork: true) }
  scope :pinned, -> { where(pinned: true) }
  scope :recently_viewed, -> { where.not(last_viewed_at: nil).order(last_viewed_at: :desc) }
  scope :active_this_week, -> {
    cutoff_date = 7.days.ago.to_date
    where("date(substr(last_commit_date, 1, 10)) >= date(?)", cutoff_date)
  }
  scope :stalled, -> {
    cutoff_14 = 14.days.ago.to_date
    cutoff_60 = 60.days.ago.to_date
    where("date(substr(last_commit_date, 1, 10)) < date(?)", cutoff_14)
      .where("date(substr(last_commit_date, 1, 10)) >= date(?)", cutoff_60)
  }

  # Associations
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :notes, dependent: :destroy
  has_many :project_goals, dependent: :destroy
  has_many :goals, through: :project_goals

  # Create or update project from ProjectData instance
  def self.create_or_update_from_data(project_data)
    find_or_initialize_by(path: project_data.path).tap do |project|
      project.name = project_data.name
      project.last_commit_date = project_data.last_commit_date
      project.last_commit_message = project_data.last_commit_message
      project.metadata = project_data.metadata
      project.is_fork = project_data.is_fork
      project.save!
    end
  end

  # Helper methods
  def status
    return "wip" if last_commit_message&.match?(/WIP|TODO|FIXME|in progress/i)
    return "deployed" if metadata&.dig("deployment_status")&.include?("likely deployed")

    days_ago = (Date.today - Date.parse(last_commit_date)).to_i
    if days_ago < 7
      "active"
    elsif days_ago < 30
      "recent"
    else
      "paused"
    end
  rescue
    "unknown"
  end

  def relative_last_commit_date
    days_ago = (Date.today - Date.parse(last_commit_date)).to_i
    if days_ago == 0
      "today"
    elsif days_ago == 1
      "yesterday"
    elsif days_ago < 7
      "#{days_ago} days ago"
    elsif days_ago < 30
      "#{(days_ago / 7).round} week#{(days_ago / 7).round > 1 ? 's' : ''} ago"
    elsif days_ago < 365
      "#{(days_ago / 30).round} month#{(days_ago / 30).round > 1 ? 's' : ''} ago"
    else
      "#{(days_ago / 365).round} year#{(days_ago / 365).round > 1 ? 's' : ''} ago"
    end
  rescue
    "unknown"
  end

  def tech_stack_array
    metadata&.dig("tech_stack") || []
  end

  def project_type
    metadata&.dig("inferred_type") || "unknown"
  end

  def commit_count_8m
    metadata&.dig("commit_count_8m") || 0
  end

  def description
    metadata&.dig("description") || ""
  end

  def truncated_description(length = 60)
    desc = description
    return "" if desc.blank?

    desc.length > length ? "#{desc[0...length]}..." : desc
  end

  def recent_note
    notes.first
  end

  def github_url
    git_remote = metadata&.dig("git_remote")
    return nil unless git_remote&.include?("github.com")

    # Convert SSH format to HTTPS
    if git_remote.start_with?("git@github.com:")
      git_remote = git_remote.sub("git@github.com:", "https://github.com/")
    end

    # Remove .git suffix if present
    git_remote = git_remote.sub(/\.git$/, "")

    git_remote
  end

  def plans_count
    metadata&.dig("plans_count") || 0
  end

  def ai_docs_count
    metadata&.dig("ai_docs_count") || 0
  end

  def claude_description
    metadata&.dig("claude_description")
  end

  def docs_count
    plans_count + ai_docs_count
  end
end
