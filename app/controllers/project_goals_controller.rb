class ProjectGoalsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :set_project

  def create
    @goal = Goal.find_or_create_by(name: project_goal_params[:goal_name].strip.downcase)
    @project_goal = @project.project_goals.build(goal: @goal)

    respond_to do |format|
      if @project_goal.save
        format.turbo_stream
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "goal_form",
            partial: "project_goals/form",
            locals: { project: @project, error: @project_goal.errors.full_messages.join(", ") }
          )
        }
      end
    end
  end

  def update
    @project_goal = @project.project_goals.find(params[:id])

    respond_to do |format|
      if @project_goal.update(status: params[:status])
        format.turbo_stream
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            dom_id(@project_goal),
            partial: "project_goals/project_goal",
            locals: { project: @project, project_goal: @project_goal }
          )
        }
      end
    end
  end

  def destroy
    @project_goal = @project.project_goals.find(params[:id])
    @project_goal.destroy

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def project_goal_params
    params.require(:project_goal).permit(:goal_name)
  end
end
