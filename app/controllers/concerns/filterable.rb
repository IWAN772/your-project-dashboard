# frozen_string_literal: true

module Filterable
  extend ActiveSupport::Concern

  private

  def apply_filters(relation)
    relation = apply_search_filter(relation)
    relation = apply_ownership_filter(relation)
    relation = apply_status_filter(relation)
    relation = apply_tech_stack_filter(relation)
    relation = apply_type_filter(relation)
    relation
  end

  def apply_search_filter(relation)
    return relation if filter_params[:search].blank?

    relation.search(filter_params[:search])
  end

  def apply_ownership_filter(relation)
    return relation if filter_params[:ownership].blank? || filter_params[:ownership] == "all"

    case filter_params[:ownership]
    when "own"
      relation.own_projects
    when "forks"
      relation.forks
    else
      relation
    end
  end

  def apply_status_filter(relation)
    return relation if filter_params[:status].blank? || filter_params[:status] == "all"

    relation.by_status(filter_params[:status])
  end

  def apply_tech_stack_filter(relation)
    return relation if filter_params[:tech_stack].blank?

    relation.by_tech_stack(filter_params[:tech_stack])
  end

  def apply_type_filter(relation)
    return relation if filter_params[:type].blank? || filter_params[:type] == "all"

    relation.by_type(filter_params[:type])
  end

  def apply_sort(relation)
    sort_column = params[:sort] || "last_commit_date"
    sort_direction = params[:direction] || "desc"

    case sort_column
    when "name"
      relation.order(name: sort_direction)
    when "last_commit_date"
      relation.order(last_commit_date: sort_direction)
    when "commit_count"
      relation.order(Arel.sql("CAST(json_extract(metadata, '$.commit_count_8m') AS INTEGER) #{sort_direction}"))
    else
      relation.order(last_commit_date: :desc)
    end
  end

  def filter_params
    params.permit(:search, :ownership, :status, :tech_stack, :type, :sort, :direction, :page)
  end

  def store_filters_in_session
    session[:project_filters] ||= {}
    session[:project_filters].merge!(filter_params.to_h)
  end

  def restore_filters_from_session
    return unless session[:project_filters].present?

    session[:project_filters].each do |key, value|
      params[key] ||= value
    end
  end
end
