# frozen_string_literal: true

class NotesController < ApplicationController
  before_action :set_project

  def create
    @note = @project.notes.build(note_params)

    respond_to do |format|
      if @note.save
        format.turbo_stream
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "note_form",
            partial: "notes/form",
            locals: { project: @project, error: @note.errors.full_messages.join(", ") }
          )
        }
      end
    end
  end

  def destroy
    @note = @project.notes.find(params[:id])
    @note.destroy

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def note_params
    params.require(:note).permit(:content)
  end
end
