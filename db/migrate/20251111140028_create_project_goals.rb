class CreateProjectGoals < ActiveRecord::Migration[8.2]
  def change
    create_table :project_goals do |t|
      t.references :project, null: false, foreign_key: true
      t.references :goal, null: false, foreign_key: true
      t.string :status, null: false, default: "not_started"

      t.timestamps
    end

    add_index :project_goals, [:project_id, :goal_id], unique: true
  end
end
