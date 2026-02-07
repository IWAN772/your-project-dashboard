# frozen_string_literal: true

require "find"
require "date"
require_relative "project_data"

class ProjectScanner
  attr_reader :projects, :skipped_projects

  def initialize(root_path, cutoff_date)
    @root_path = File.expand_path(root_path)
    @cutoff_date = cutoff_date
    @projects = []
    @skipped_projects = []
  end

  def scan
    puts "Scanning for git repositories in #{@root_path}..."
    puts "Looking for projects with commits since #{@cutoff_date}..."
    puts

    repo_paths = find_all_git_repos
    puts "Found #{repo_paths.size} git repositories"
    puts

    puts "Processing projects..."
    repo_paths.each_with_index do |repo_path, index|
      project_name = File.basename(repo_path)
      print "  [#{index + 1}/#{repo_paths.size}] #{project_name.ljust(40)} "

      project = ProjectData.new(repo_path)

      if project.valid?
        commit_date = Date.parse(project.last_commit_date)

        if commit_date >= @cutoff_date
          @projects << project

          # Show detailed status
          fork_status = project.is_fork ? "[Fork]" : "[Own]"
          type_badge = project.metadata[:inferred_type] || "unknown"

          puts "✓ #{fork_status.ljust(7)} #{type_badge.ljust(12)} (#{project.last_commit_date.split[0]})"
        else
          @skipped_projects << { path: repo_path, reason: "too old (#{commit_date})" }
          puts "⊗ too old (#{commit_date})"
        end
      else
        @skipped_projects << { path: repo_path, reason: "invalid/no commits" }
        puts "⊗ invalid"
      end
    rescue => e
      @skipped_projects << { path: repo_path, reason: "error: #{e.message}" }
      puts "✗ error: #{e.message[0..40]}"
    end

    puts
    puts "Processed #{@projects.size} projects, skipped #{@skipped_projects.size}"
  end

  def save_to_database
    puts
    puts "Saving to database..."

    @projects.each_with_index do |project_data, index|
      project_name = project_data.name.ljust(40)
      fork_status = project_data.is_fork ? "[Fork]" : "[Own]"

      print "  [#{index + 1}/#{@projects.size}] #{project_name} #{fork_status}... "

      Project.create_or_update_from_data(project_data)
      puts "✓"
    end

    puts
    puts "Saved #{@projects.size} projects to database"
    puts "Total projects in database: #{Project.count}"

    # Show counts
    own_count = Project.where(is_fork: false).count
    fork_count = Project.where(is_fork: true).count
    puts "  → Your projects: #{own_count}"
    puts "  → Forked projects: #{fork_count}"
  end

  def print_summary
    puts
    puts "=" * 80
    puts "SCAN SUMMARY"
    puts "=" * 80
    puts
    puts "Total projects found: #{@projects.size}"
    puts "Skipped: #{@skipped_projects.size}"
    puts

    if @projects.any?
      # Ownership breakdown
      own_projects = @projects.count { |p| !p.is_fork }
      forked_projects = @projects.count { |p| p.is_fork }

      puts "Ownership breakdown:"
      puts "  Your projects: #{own_projects}"
      puts "  Forked projects: #{forked_projects}"
      puts

      puts "Projects by type:"
      type_counts = @projects.group_by { |p| p.metadata[:inferred_type] }
      type_counts.each do |type, projs|
        puts "  #{type}: #{projs.size}"
      end
      puts

      puts "Most recent projects:"
      @projects.sort_by { |p| p.last_commit_date }.reverse.first(10).each do |project|
        fork_badge = project.is_fork ? "[Fork]" : "[Own] "
        puts "  • #{fork_badge} #{project.name.ljust(30)} (#{project.last_commit_date.split[0]})"
      end
    end

    if @skipped_projects.any?
      puts
      puts "Skipped projects (#{@skipped_projects.size}):"
      @skipped_projects.first(10).each do |skipped|
        basename = File.basename(skipped[:path])
        puts "  • #{basename.ljust(30)} - #{skipped[:reason]}"
      end
      puts "  ... and #{@skipped_projects.size - 10} more" if @skipped_projects.size > 10
    end

    puts
    puts "=" * 80
  end

  private

  def find_all_git_repos
    repos = []
    processed_paths = Set.new
    dirs_checked = 0
    last_output_time = Time.now

    Find.find(@root_path) do |path|
      # Skip if we've already processed this path's parent as a repo
      # Ensure we check for actual subdirectories, not just string prefixes
      next if processed_paths.any? { |p| path.start_with?(p + "/") }

      # Show progress for directories (but throttle output to avoid spam)
      if File.directory?(path)
        dirs_checked += 1
        relative_path = path.sub(@root_path + "/", "")

        # Output every 50 directories or every 0.5 seconds, whichever comes first
        if dirs_checked % 50 == 0 || (Time.now - last_output_time) > 0.5
          print "\r  Scanning: #{relative_path[0..60].ljust(62)} (#{dirs_checked} dirs, #{repos.size} repos)"
          $stdout.flush
          last_output_time = Time.now
        end
      end

      # Skip hidden directories except .git
      if File.directory?(path) && File.basename(path).start_with?(".")
        if File.basename(path) == ".git"
          # Found a git repo!
          repo_path = File.dirname(path)
          repos << repo_path
          processed_paths << repo_path

          # Show immediate feedback when a repo is found
          relative_repo = repo_path.sub(@root_path + "/", "")
          print "\r  ✓ Found repo: #{relative_repo[0..60].ljust(62)} (#{repos.size} total)\n"
          last_output_time = Time.now

          # Don't descend into this .git directory
          Find.prune
        else
          # Skip other hidden directories
          Find.prune
        end
        next
      end

      # Skip node_modules
      if File.directory?(path) && File.basename(path) == "node_modules"
        Find.prune
        next
      end

      # If we're inside a discovered repo, don't descend further
      # (This handles the case where we might have nested repos)
      if processed_paths.any? { |repo| path.start_with?(repo + "/") }
        Find.prune
      end
    end

    # Clear the progress line
    print "\r" + " " * 80 + "\r"

    repos.sort
  rescue => e
    puts "Error during repository discovery: #{e.message}"
    puts e.backtrace.first(5)
    repos
  end
end
