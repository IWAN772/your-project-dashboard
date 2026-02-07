# frozen_string_literal: true

class ProjectsController < ApplicationController
  include Filterable
  before_action :load_left_rail_data

  def index
    # Fetch 12 most recent active projects for "Quick Resume" cards
    # Filter in Ruby since status is a computed method
    all_recent = Project.includes(:tags, notes: [], project_goals: :goal)
                        .where(is_fork: false)
                        .order(last_commit_date: :desc)
                        .limit(30)

    @recent_projects = all_recent.select { |p| ["active", "wip", "recent", "deployed"].include?(p.status) }.take(12)

    @projects = Project.all

    # Apply smart group filter if present
    if params[:smart_group].present?
      case params[:smart_group]
      when "active_this_week"
        @projects = @projects.active_this_week
      when "stalled"
        @projects = @projects.stalled
      end
    end

    @projects = apply_filters(@projects)
    @projects = apply_sort(@projects)
    @projects = @projects.page(params[:page]).per(25)

    # Cache these expensive queries (invalidate when projects change)
    @tech_stacks = Rails.cache.fetch("project_tech_stacks", expires_in: 1.hour) do
      Project.pluck(:metadata)
             .map { |m| m&.dig("tech_stack") }
             .flatten
             .compact
             .uniq
             .sort
    end

    @project_types = Rails.cache.fetch("project_types", expires_in: 1.hour) do
      Project.pluck(:metadata)
             .map { |m| m&.dig("inferred_type") }
             .compact
             .uniq
             .sort
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @project = Project.includes(:tags, :notes, project_goals: :goal).find(params[:id])

    # Track view for recently viewed
    @project.update_column(:last_viewed_at, Time.current)

    # Get previous and next projects for navigation
    @previous_project = Project.where("id < ?", @project.id).order(id: :desc).first
    @next_project = Project.where("id > ?", @project.id).order(id: :asc).first
  end

  def toggle_pin
    @project = Project.find(params[:id])
    @project.update(pinned: !@project.pinned)
    redirect_back fallback_location: project_path(@project)
  end

  private

  def load_left_rail_data
    @pinned_projects = Project.pinned.order(:name).limit(15)
    @recently_viewed_projects = Project.recently_viewed.limit(10)
    @active_this_week_count = Project.active_this_week.count
    @stalled_count = Project.stalled.count
  end
end
