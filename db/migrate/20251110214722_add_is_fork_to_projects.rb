class AddIsForkToProjects < ActiveRecord::Migration[8.2]
  def change
    add_column :projects, :is_fork, :boolean, default: false, null: false
    add_index :projects, :is_fork
  end
end
