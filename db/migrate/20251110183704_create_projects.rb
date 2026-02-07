class CreateProjects < ActiveRecord::Migration[8.2]
  def change
    create_table :projects do |t|
      t.string :path
      t.string :name
      t.string :last_commit_date
      t.text :last_commit_message
      t.json :metadata

      t.timestamps
    end
    add_index :projects, :path, unique: true
    add_index :projects, :last_commit_date
  end
end
