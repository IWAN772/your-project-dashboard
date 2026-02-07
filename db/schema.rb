# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.2].define(version: 2026_02_02_014102) do
  create_table "goals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_goals_on_name", unique: true
  end

  create_table "notes", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "created_at"], name: "index_notes_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_notes_on_project_id"
  end

  create_table "project_goals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "goal_id", null: false
    t.integer "project_id", null: false
    t.string "status", default: "not_started", null: false
    t.datetime "updated_at", null: false
    t.index ["goal_id"], name: "index_project_goals_on_goal_id"
    t.index ["project_id", "goal_id"], name: "index_project_goals_on_project_id_and_goal_id", unique: true
    t.index ["project_id"], name: "index_project_goals_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_fork", default: false, null: false
    t.string "last_commit_date"
    t.text "last_commit_message"
    t.datetime "last_viewed_at"
    t.json "metadata"
    t.string "name"
    t.string "path"
    t.boolean "pinned", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["is_fork"], name: "index_projects_on_is_fork"
    t.index ["last_commit_date"], name: "index_projects_on_last_commit_date"
    t.index ["last_viewed_at"], name: "index_projects_on_last_viewed_at"
    t.index ["path"], name: "index_projects_on_path", unique: true
    t.index ["pinned"], name: "index_projects_on_pinned"
  end

  create_table "taggings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "project_id", null: false
    t.integer "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "tag_id"], name: "index_taggings_on_project_id_and_tag_id", unique: true
    t.index ["project_id"], name: "index_taggings_on_project_id"
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  add_foreign_key "notes", "projects"
  add_foreign_key "project_goals", "goals"
  add_foreign_key "project_goals", "projects"
  add_foreign_key "taggings", "projects"
  add_foreign_key "taggings", "tags"
end
