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

ActiveRecord::Schema[8.1].define(version: 2026_01_14_181406) do
  create_table "postal_codes", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "location_type"
    t.string "name_en"
    t.string "name_km"
    t.string "postal_code"
    t.datetime "updated_at", null: false
    t.index ["location_type"], name: "index_postal_codes_on_location_type"
    t.index ["name_en"], name: "index_postal_codes_on_name_en"
    t.index ["postal_code"], name: "index_postal_codes_on_postal_code"
  end

  # Virtual tables defined in this database.
  # Note that virtual tables may not work with other database engines. Be careful if changing database.
