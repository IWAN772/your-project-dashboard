# frozen_string_literal: true

require "date"
require "json"
require "find"

class ProjectData
  attr_accessor :path, :name, :last_commit_date, :last_commit_message, :metadata

  def initialize(path)
    @path = File.expand_path(path)
    @name = derive_name
    @metadata = {}
    @errors = []
    extract_git_data
    extract_metadata
  end

  def valid?
    !@last_commit_date.nil?
  end

  private

  def derive_name
    File.basename(@path)
  end

  def extract_git_data
    return unless File.directory?(File.join(@path, ".git"))

    # Get last commit info
    result = run_git_command("log -1 --format='%ai|%s|%an'")
    if result && !result.empty?
      parts = result.split("|")
      @last_commit_date = parts[0]
      @last_commit_message = parts[1]
      @metadata[:last_commit_author] = parts[2]
    end

    # Get recent commits (last 10)
    recent = run_git_command("log -10 --format='%ai|%s'")
    if recent
      @metadata[:recent_commits] = recent.split("\n").map do |line|
        date, message = line.split("|", 2)
        { date: date, message: message }
      end
    end

    # Count commits in last 8 months
    cutoff_date = "2025-03-10"
    count = run_git_command("rev-list --count --since='#{cutoff_date}' HEAD")
    @metadata[:commit_count_8m] = count.to_i if count

    # Get unique contributors
    contributors = run_git_command("log --format='%an' | sort -u")
    @metadata[:contributors] = contributors.split("\n") if contributors

    # Get git remote URL
    remote_url = run_git_command("config --get remote.origin.url")
    @metadata[:git_remote] = remote_url if remote_url && !remote_url.empty?
  rescue => e
    @errors << "Git extraction error: #{e.message}"
  end

  def extract_metadata
    @metadata[:reference_files] = find_reference_files
    @metadata[:description] = infer_description
    @metadata[:current_state] = infer_current_state
    @metadata[:tech_stack] = detect_tech_stack
    @metadata[:inferred_type] = infer_project_type
    @metadata[:deployment_status] = infer_deployment_status
    @metadata[:nested_repos] = check_nested_repos
    @metadata[:plans_count] = count_markdown_files("plans")
    @metadata[:ai_docs_count] = count_markdown_files(".ai")
    @metadata[:claude_description] = extract_claude_description
    @metadata[:errors] = @errors unless @errors.empty?
  end

  def find_reference_files
    files = { root: [], ai: [], cursor: [], tasks: [], docs: [] }

    # Root level files
    ["README.md", "CLAUDE.md", "AGENT.md", "CHANGELOG.md"].each do |filename|
      path = File.join(@path, filename)
      files[:root] << filename if File.exist?(path)
    end

    # .ai directory
    ai_dir = File.join(@path, ".ai")
    if File.directory?(ai_dir)
      files[:ai] = Dir.glob(File.join(ai_dir, "**/*.md")).map { |f| f.sub("#{ai_dir}/", "") }
    end

    # .cursor directory
    cursor_dir = File.join(@path, ".cursor")
    if File.directory?(cursor_dir)
      files[:cursor] = Dir.glob(File.join(cursor_dir, "**/*.md")).map { |f| f.sub("#{cursor_dir}/", "") }
    end

    # tasks directory
    tasks_dir = File.join(@path, "tasks")
    if File.directory?(tasks_dir)
      files[:tasks] = Dir.glob(File.join(tasks_dir, "*.md")).map { |f| f.sub("#{tasks_dir}/", "") }
    end

    # docs directory
    docs_dir = File.join(@path, "docs")
    if File.directory?(docs_dir)
      files[:docs] = Dir.glob(File.join(docs_dir, "*.md")).map { |f| f.sub("#{docs_dir}/", "") }
    end

    files.reject { |_, v| v.empty? }
  rescue => e
    @errors << "Reference file discovery error: #{e.message}"
    {}
  end

  def infer_description
    # Priority order: .ai/PROJECT_STATUS.md > .cursor/PROJECT_STATUS.md > CLAUDE.md > AGENT.md > README.md
    candidates = [
      File.join(@path, ".ai/PROJECT_STATUS.md"),
      File.join(@path, ".ai/README.md"),
      File.join(@path, ".cursor/PROJECT_STATUS.md"),
      File.join(@path, ".cursor/README.md"),
      File.join(@path, "CLAUDE.md"),
      File.join(@path, "AGENT.md"),
      File.join(@path, "README.md")
    ]

    candidates.each do |file_path|
      next unless File.exist?(file_path)

      description = extract_description_from_file(file_path)
      return description if description && !description.empty?
    end

    # Fallback to directory name
    @name.gsub(/[-_]/, " ").split.map(&:capitalize).join(" ")
  rescue => e
    @errors << "Description extraction error: #{e.message}"
    @name
  end

  def extract_description_from_file(file_path)
    content = read_file_safely(file_path, max_lines: 100)
    return nil unless content

    # Try to find a description section
    if content =~ /##\s*(Description|Overview|About|Summary)\s*\n+(.+?)(?=\n##|\z)/m
      return $2.strip.gsub(/\n+/, " ").slice(0, 500)
    end

    # Try to get first paragraph after title
    lines = content.split("\n").reject { |l| l.strip.empty? || l.start_with?("#") }
    first_para = lines.first(3).join(" ").strip
    return first_para.slice(0, 500) if first_para.length > 20

    # Try to get content after H1
    if content =~ /^#[^#].+?\n+(.+?)(?=\n##|\z)/m
      return $1.strip.gsub(/\n+/, " ").slice(0, 500)
    end

    nil
  end

  def infer_current_state
    state_parts = []

    # Check TODO.md for open tasks
    todo_paths = [
      File.join(@path, ".ai/TODO.md"),
      File.join(@path, ".cursor/TODO.md"),
      File.join(@path, "TODO.md")
    ]

    todo_paths.each do |todo_path|
      if File.exist?(todo_path)
        content = read_file_safely(todo_path)
        if content
          open_tasks = content.scan(/- \[ \]/).count
          closed_tasks = content.scan(/- \[x\]/i).count

          if open_tasks > 0
            state_parts << "#{open_tasks} open task#{'s' if open_tasks > 1}"
          end
          if closed_tasks > 0
            state_parts << "#{closed_tasks} completed task#{'s' if closed_tasks > 1}"
          end
        end
        break if !state_parts.empty?
      end
    end

    # Check last commit message for keywords
    if @last_commit_message
      if @last_commit_message =~ /WIP|TODO|FIXME|in progress/i
        state_parts << "work in progress"
      elsif @last_commit_message =~ /done|complete|finish|ship/i
        state_parts << "recently completed"
      end
    end

    # Check commit recency
    if @last_commit_date
      days_ago = (Date.today - Date.parse(@last_commit_date)).to_i
      if days_ago < 7
        state_parts << "active (committed #{days_ago} day#{'s' if days_ago > 1} ago)"
      elsif days_ago < 30
        state_parts << "recently active (committed #{days_ago} days ago)"
      else
        state_parts << "paused (last commit #{days_ago} days ago)"
      end
    end

    state_parts.join(", ")
  rescue => e
    @errors << "State inference error: #{e.message}"
    "unknown"
  end

  def detect_tech_stack
    stack = []

    # Check for Ruby/Rails
    if File.exist?(File.join(@path, "Gemfile"))
      stack << "ruby"
      gemfile_content = read_file_safely(File.join(@path, "Gemfile"))
      stack << "rails" if gemfile_content&.include?("rails")
    end

    # Check for Node/JavaScript
    if File.exist?(File.join(@path, "package.json"))
      stack << "node"
      package_json = read_file_safely(File.join(@path, "package.json"))
      if package_json
        stack << "nextjs" if package_json.include?("next")
        stack << "react" if package_json.include?("react")
        stack << "vue" if package_json.include?("vue")
      end
    end

    # Check for Python
    if File.exist?(File.join(@path, "requirements.txt")) || File.exist?(File.join(@path, "pyproject.toml"))
      stack << "python"
    end

    # Check for Go
    stack << "go" if File.exist?(File.join(@path, "go.mod"))

    # Check for specific directories
    stack << "rails-app" if File.exist?(File.join(@path, "config/routes.rb"))
    stack << "web-app" if File.directory?(File.join(@path, "app"))

    stack.uniq
  rescue => e
    @errors << "Tech stack detection error: #{e.message}"
    []
  end

  def infer_project_type
    return "rails-app" if @metadata[:tech_stack]&.include?("rails")
    return "node-app" if @metadata[:tech_stack]&.include?("node")
    return "python-app" if @metadata[:tech_stack]&.include?("python")
    return "docs" if @metadata[:reference_files]&.dig(:docs)&.any?
    return "script" if Dir.glob(File.join(@path, "*.rb")).any? || Dir.glob(File.join(@path, "*.js")).any?
    "unknown"
  rescue
    "unknown"
  end

  def infer_deployment_status
    deployed_indicators = []

    # Check for bin/deploy script
    deploy_script = File.join(@path, "bin/deploy")
    deployed_indicators << "has deploy script" if File.exist?(deploy_script)

    # Check package.json for deploy scripts
    package_json_path = File.join(@path, "package.json")
    if File.exist?(package_json_path)
      content = read_file_safely(package_json_path)
      if content
        deployed_indicators << "has deploy npm script" if content.include?('"deploy"')
        deployed_indicators << "has build script" if content.include?('"build"')
      end
    end

    # Check README for deployment mentions
    readme_path = File.join(@path, "README.md")
    if File.exist?(readme_path)
      content = read_file_safely(readme_path, max_lines: 50)
      if content
        deployed_indicators << "deployment documented" if content =~ /deploy|production|live|hosting/i
      end
    end

    # Check for common deployment config files
    deployed_indicators << "has Dockerfile" if File.exist?(File.join(@path, "Dockerfile"))
    deployed_indicators << "has docker-compose" if File.exist?(File.join(@path, "docker-compose.yml"))
    deployed_indicators << "has Procfile" if File.exist?(File.join(@path, "Procfile"))

    return "likely deployed (#{deployed_indicators.join(', ')})" unless deployed_indicators.empty?
    "deployment status unknown"
  rescue => e
    @errors << "Deployment status inference error: #{e.message}"
    "unknown"
  end

  def check_nested_repos
    nested = []

    # Find any .git directories within the project (but not the main one)
    Find.find(@path) do |path|
      # Skip the main .git directory
      if path == File.join(@path, ".git")
        Find.prune
        next
      end

      # Skip node_modules
      if path.include?("node_modules")
        Find.prune
        next
      end

      # Check if this is a nested .git directory
      if File.directory?(path) && File.basename(path) == ".git"
        parent_dir = File.dirname(path)
        nested << parent_dir.sub("#{@path}/", "")
        Find.prune
      end
    end

    nested
  rescue => e
    @errors << "Nested repo check error: #{e.message}"
    []
  end

  def run_git_command(command)
    result = `cd #{@path} && git #{command} 2>/dev/null`.strip
    result.empty? ? nil : result
  end

  def read_file_safely(file_path, max_lines: 1000)
    return nil unless File.exist?(file_path)
    return nil if File.size(file_path) > 500_000 # Skip files > 500KB

    content = File.readlines(file_path, encoding: "UTF-8").first(max_lines).join
    content
  rescue => e
    @errors << "File read error (#{File.basename(file_path)}): #{e.message}"
    nil
  end

  def count_markdown_files(dir)
    dir_path = File.join(@path, dir)
    return 0 unless File.directory?(dir_path)

    archive_path = File.join(dir_path, "archive")
    Dir.glob(File.join(dir_path, "*.md")).reject { |f| f.start_with?(archive_path) }.count
  rescue => e
    @errors << "Markdown count error (#{dir}): #{e.message}"
    0
  end

  def extract_claude_description
    claude_path = File.join(@path, "CLAUDE.md")
    return nil unless File.exist?(claude_path)

    content = read_file_safely(claude_path, max_lines: 100)
    return nil unless content

    lines = content.lines
    # Skip YAML frontmatter if present
    if lines.first&.strip == "---"
      lines.shift
      lines.shift while lines.first && lines.first.strip != "---"
      lines.shift if lines.first&.strip == "---"
    end

    # Skip headings and blank lines to find first paragraph
    lines.shift while lines.first&.match?(/^(#|\s*$)/)

    paragraph = []
    lines.each do |line|
      break if line.strip.empty? && paragraph.any?
      paragraph << line.strip unless line.strip.empty?
    end

    text = paragraph.join(" ")
    text.length > 500 ? text[0, 500] + "..." : text
  rescue => e
    @errors << "CLAUDE.md extraction error: #{e.message}"
    nil
  end
end
