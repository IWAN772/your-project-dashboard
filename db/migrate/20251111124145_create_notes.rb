class CreateNotes < ActiveRecord::Migration[8.2]
  def change
    create_table :notes do |t|
      t.references :project, null: false, foreign_key: true
      t.text :content, null: false
      t.timestamps
    end

    add_index :notes, [:project_id, :created_at]
  end
end
