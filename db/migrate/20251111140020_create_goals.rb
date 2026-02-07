class CreateGoals < ActiveRecord::Migration[8.2]
  def change
    create_table :goals do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end
    add_index :goals, :name, unique: true
  end
end
