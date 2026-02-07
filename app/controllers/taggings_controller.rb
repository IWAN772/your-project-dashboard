# frozen_string_literal: true

class TaggingsController < ApplicationController
  before_action :set_project

  def create
    tag_name = params[:tag_name]&.strip
    return head :unprocessable_entity if tag_name.blank?

    tag = Tag.find_or_create_by!(name: tag_name)
    @tagging = @project.taggings.build(tag: tag)

    respond_to do |format|
      if @tagging.save
        format.turbo_stream
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "tag_form",
            partial: "taggings/form",
            locals: { project: @project, error: "Tag already exists on this project" }
          )
        }
      end
    end
  end

  def destroy
    @tagging = @project.taggings.find(params[:id])
    @tagging.destroy

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end
end
