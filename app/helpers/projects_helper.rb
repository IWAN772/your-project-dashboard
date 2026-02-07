# frozen_string_literal: true

module ProjectsHelper
  def status_badge(status)
    colors = {
      "active" => "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400",
      "recent" => "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400",
      "paused" => "bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400",
      "wip" => "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-400",
      "deployed" => "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-400",
      "unknown" => "bg-gray-100 text-gray-600 dark:bg-gray-900/30 dark:text-gray-500"
    }

    color_class = colors[status] || colors["unknown"]
    dot_colors = {
      "active" => "bg-green-500",
      "recent" => "bg-blue-500",
      "paused" => "bg-gray-400",
      "wip" => "bg-amber-500",
      "deployed" => "bg-emerald-500",
      "unknown" => "bg-gray-400"
    }
    dot_color = dot_colors[status] || dot_colors["unknown"]

    content_tag(:span, class: "inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium #{color_class}") do
      concat content_tag(:span, "", class: "w-2 h-2 rounded-full #{dot_color}")
      concat status.capitalize
    end
  end

  def tech_stack_badges(tech_stack)
    return "" if tech_stack.blank?

    tech_stack.map do |tech|
      content_tag(:span, class: "inline-flex items-center gap-1 px-2 py-1 rounded text-xs font-medium bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300") do
        concat tech_icon(tech)
        concat tech.capitalize
      end
    end.join(" ").html_safe
  end

  def tech_icon(tech)
    icons = {
      "ruby" => "💎",
      "rails" => "🛤️",
      "node" => "🟢",
      "react" => "⚛️",
      "nextjs" => "▲",
      "python" => "🐍",
      "go" => "🐹",
      "vue" => "🖖"
    }

    icon = icons[tech.downcase] || "📦"
    content_tag(:span, icon, class: "text-sm", "aria-hidden" => "true")
  end

  def project_type_badge(type)
    colors = {
      "rails-app" => "bg-red-50 text-red-700 border-red-200 dark:bg-red-900/20 dark:text-red-400 dark:border-red-800",
      "node-app" => "bg-green-50 text-green-700 border-green-200 dark:bg-green-900/20 dark:text-green-400 dark:border-green-800",
      "python-app" => "bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-900/20 dark:text-blue-400 dark:border-blue-800",
      "docs" => "bg-purple-50 text-purple-700 border-purple-200 dark:bg-purple-900/20 dark:text-purple-400 dark:border-purple-800",
      "script" => "bg-yellow-50 text-yellow-700 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-400 dark:border-yellow-800",
      "unknown" => "bg-gray-50 text-gray-700 border-gray-200 dark:bg-gray-900/20 dark:text-gray-400 dark:border-gray-800"
    }

    color_class = colors[type] || colors["unknown"]
    display_name = type.split("-").map(&:capitalize).join(" ")

    content_tag(:span, display_name, class: "inline-flex items-center px-2 py-1 rounded border text-xs font-medium #{color_class}")
  end

  def sort_link(column, title, current_sort, current_direction)
    direction = (current_sort == column && current_direction == "asc") ? "desc" : "asc"
    aria_sort = if current_sort == column
                  current_direction == "asc" ? "ascending" : "descending"
                else
                  "none"
                end

    link_to title, projects_path(filter_params(overrides: { sort: column, direction: direction })),
            class: "flex items-center gap-2 hover:bg-gray-100 dark:hover:bg-gray-800 px-2 py-1 rounded transition-colors",
            data: { turbo_frame: "results" },
            "aria-sort" => aria_sort do
      concat title
      if current_sort == column
        icon_class = current_direction == "asc" ? "rotate-0" : "rotate-180"
        concat content_tag(:svg, class: "w-4 h-4 transition-transform #{icon_class}", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor") do
          tag.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M5 15l7-7 7 7")
        end
      end
    end
  end

  # Safely builds query params for links, preserving filters
  # @param overrides [Hash] params to override (e.g., { sort: "name", direction: "asc" })
  # @param exclude [Array<Symbol>] params to exclude (e.g., [:search] to remove search)
  def filter_params(overrides: {}, exclude: [])
    allowed = [:search, :ownership, :status, :tech_stack, :type, :sort, :direction, :page]
    base = params.permit(*allowed).to_h.symbolize_keys

    exclude.each { |key| base.delete(key) }
    base.merge(overrides).compact
  end

  def active_filter_count
    count = 0
    count += 1 if params[:search].present?
    count += 1 if params[:ownership].present? && params[:ownership] != "all"
    count += 1 if params[:status].present? && params[:status] != "all"
    count += 1 if params[:tech_stack].present?
    count += 1 if params[:type].present? && params[:type] != "all"
    count
  end

  def goal_badge(goal_name, status = nil)
    base_class = "inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium"

    status_colors = {
      "not_started" => "bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400",
      "in_progress" => "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
      "completed" => "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
    }

    status_icons = {
      "not_started" => "○",
      "in_progress" => "◐",
      "completed" => "●"
    }

    color = status ? status_colors[status] : status_colors["not_started"]
    icon = status ? status_icons[status] : status_icons["not_started"]

    content_tag(:span, class: "#{base_class} #{color}") do
      concat content_tag(:span, icon, class: "text-xs")
      concat goal_name.titleize
    end
  end

  def status_color(status)
    colors = {
      "not_started" => "text-gray-600 dark:text-gray-400",
      "in_progress" => "text-blue-700 dark:text-blue-400",
      "completed" => "text-green-700 dark:text-green-400"
    }
    colors[status] || colors["not_started"]
  end
end
