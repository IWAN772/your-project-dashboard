class CreateTagsAndTaggings < ActiveRecord::Migration[8.2]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.timestamps
    end

    add_index :tags, :name, unique: true

    create_table :taggings do |t|
      t.references :project, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end

    add_index :taggings, [:project_id, :tag_id], unique: true
  end
end
