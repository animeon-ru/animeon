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

ActiveRecord::Schema[7.1].define(version: 2026_01_24_184842) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "animes", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "episodes", default: 0, null: false
    t.string "status"
    t.decimal "user_rating", default: "0.0", null: false
    t.string "franchise"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kind"
    t.integer "duration"
    t.string "age_rating"
    t.string "russian", default: "", null: false
    t.string "english"
    t.string "japanese"
    t.integer "shiki_id"
    t.string "season"
    t.integer "genres", default: [], null: false, array: true
    t.integer "episodes_aired", default: 0, null: false
    t.string "poster_file_name"
    t.string "poster_content_type"
    t.bigint "poster_file_size"
    t.datetime "poster_updated_at"
    t.integer "studio_ids", default: [], null: false, array: true
    t.index ["age_rating"], name: "index_animes_on_age_rating"
    t.index ["kind"], name: "index_animes_on_kind"
    t.index ["name"], name: "index_animes_on_name"
    t.index ["russian"], name: "index_animes_on_russian"
    t.index ["user_rating"], name: "index_animes_on_user_rating"
  end

  create_table "db_modifications", force: :cascade do |t|
    t.string "table_name", null: false
    t.string "row_name", null: false
    t.bigint "target_id", null: false
    t.string "old_data", null: false
    t.string "new_data", null: false
    t.string "status", default: "created", null: false
    t.text "reason", default: "", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_db_modifications_on_status"
    t.index ["table_name", "row_name", "target_id"], name: "index_db_modifications_on_target_id"
    t.index ["user_id"], name: "index_db_modifications_on_user_id"
  end

  create_table "episodes", force: :cascade do |t|
    t.string "name"
    t.bigint "anime_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "episode_number", default: 0, null: false
    t.index ["anime_id"], name: "index_episodes_on_anime_id"
  end

  create_table "fandubs", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "members", default: [], null: false, array: true
    t.date "date_of_foundation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fandubs_videos", id: false, force: :cascade do |t|
    t.bigint "video_id", null: false
    t.bigint "fandub_id", null: false
  end

  create_table "franchises", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "animes", default: [], null: false, array: true
    t.float "score", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "genres", force: :cascade do |t|
    t.string "name"
    t.string "russian"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "genre_type"
  end

  create_table "news", force: :cascade do |t|
    t.string "title", null: false
    t.text "body", null: false
    t.string "tags", default: [], null: false, array: true
    t.boolean "comments_closed", default: false, null: false
    t.text "comments_closed_reason"
    t.bigint "user_id", null: false
    t.boolean "is_public", default: true, null: false
    t.datetime "public_after"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_news_on_user_id"
  end

  create_table "studios", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "active", default: "yes", null: false
    t.string "image_file_name"
    t.string "image_content_type"
    t.bigint "image_file_size"
    t.datetime "image_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_rates", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "target_id", null: false
    t.integer "score", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.integer "episodes", default: 0, null: false
    t.string "target_type", null: false
    t.integer "volumes", default: 0, null: false
    t.integer "chapters", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["target_id", "target_type"], name: "index_user_rates_on_target_id_and_target_type"
    t.index ["user_id", "target_id", "target_type"], name: "index_user_rates_on_user_id_and_target_id_and_target_type", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "role", default: "user", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.bigint "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "video_urls", force: :cascade do |t|
    t.string "url"
    t.bigint "video_id"
    t.string "quality"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "cached_at", default: "2026-02-02 08:16:21", null: false
    t.index ["video_id"], name: "index_video_urls_on_video_id"
  end

  create_table "videos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "episode_id"
    t.bigint "fandub_id"
    t.string "quality", array: true
    t.string "video_file_file_name"
    t.string "video_file_content_type"
    t.bigint "video_file_file_size"
    t.datetime "video_file_updated_at"
    t.integer "status", default: 0, null: false
    t.bigint "user_id", default: 1, null: false
    t.integer "views", default: 0, null: false
    t.index ["episode_id"], name: "index_videos_on_episode_id"
    t.index ["fandub_id"], name: "index_videos_on_fandub_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
