class AddPinnedAndLastViewedToProjects < ActiveRecord::Migration[8.2]
  def change
    add_column :projects, :pinned, :boolean, default: false, null: false
    add_column :projects, :last_viewed_at, :datetime
    add_index :projects, :pinned
    add_index :projects, :last_viewed_at
  end
end
