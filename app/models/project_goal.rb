class ProjectGoal < ApplicationRecord
  belongs_to :project
  belongs_to :goal

  validates :goal_id, uniqueness: { scope: :project_id }
  validates :status, presence: true, inclusion: { in: %w[not_started in_progress completed] }

  # Status enum for easier querying
  enum :status, {
    not_started: "not_started",
    in_progress: "in_progress",
    completed: "completed"
  }, default: :not_started
end
