# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140807062542) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_masters", force: true do |t|
    t.string "name"
  end

  create_table "advertisement_lists", force: true do |t|
    t.integer "advertisement_id"
    t.integer "state"
    t.integer "pref_ad_number"
    t.integer "corp_ad_number"
    t.integer "toppage_ad_number"
  end

  create_table "advertisements", force: true do |t|
    t.string   "name"
    t.string   "advertiser"
    t.string   "image_file_name"
    t.string   "alt"
    t.text     "url"
    t.datetime "begin_date"
    t.datetime "end_date"
    t.integer  "side_type"
    t.boolean  "show_in_header"
    t.integer  "corp_ad_number"
    t.integer  "pref_ad_number"
    t.integer  "state",              default: 1
    t.string   "description"
    t.text     "description_link"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "toppage_ad_number"
  end

  create_table "board_comments", force: true do |t|
    t.integer  "board_id",    null: false
    t.text     "body",        null: false
    t.string   "from",        null: false
    t.boolean  "public"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "remote_addr"
  end

  create_table "boards", force: true do |t|
    t.string  "title",      null: false
    t.integer "section_id", null: false
  end

  create_table "ckeditor_assets", force: true do |t|
    t.string   "data_file_name",               null: false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    limit: 30
    t.string   "type",              limit: 30
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ckeditor_assets", ["assetable_type", "assetable_id"], name: "idx_ckeditor_assetable", using: :btree
  add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], name: "idx_ckeditor_assetable_type", using: :btree

  create_table "cms_actions", force: true do |t|
    t.integer "action_master_id"
    t.string  "controller_name"
    t.string  "action_name"
  end

  create_table "consult_management_consult_categories", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "consult_management_consult_category_members", force: true do |t|
    t.integer  "consult_id"
    t.integer  "consult_category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "consult_management_consults", force: true do |t|
    t.string   "name"
    t.string   "link"
    t.text     "work_content"
    t.string   "contact"
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "divisions", force: true do |t|
    t.string  "name"
    t.integer "number"
    t.boolean "enable"
  end

  create_table "emergency_infos", force: true do |t|
    t.datetime "display_start_datetime", null: false
    t.datetime "display_end_datetime",   null: false
    t.text     "content",                null: false
  end

  create_table "engine_masters", force: true do |t|
    t.string  "name"
    t.boolean "enable", default: false
  end

  create_table "event_referers", force: true do |t|
    t.integer "plugin"
    t.string  "path"
    t.string  "target_path"
  end

  create_table "genres", force: true do |t|
    t.integer "parent_id"
    t.string  "name"
    t.string  "title"
    t.string  "path"
    t.text    "description"
    t.integer "original_id"
    t.integer "no"
    t.text    "uri"
    t.integer "section_id"
    t.text    "tracking_code"
    t.boolean "auth"
    t.boolean "deletable",         default: true
    t.integer "blog_folder_type",  default: 0
    t.integer "event_folder_type", default: 0
  end

  add_index "genres", ["parent_id"], name: "genres_parent_id_index", using: :btree
  add_index "genres", ["path"], name: "genres_path_index", using: :btree
  add_index "genres", ["section_id"], name: "genres_section_id_index", using: :btree

  create_table "help_actions", force: true do |t|
    t.string  "name"
    t.integer "action_master_id"
    t.integer "help_category_id"
  end

  create_table "help_categories", force: true do |t|
    t.string  "name"
    t.integer "parent_id"
    t.integer "number"
    t.boolean "navigation", default: false
  end

  create_table "help_contents", force: true do |t|
    t.text "content"
  end

  create_table "helps", force: true do |t|
    t.string  "name"
    t.integer "public",           default: 0
    t.integer "help_category_id"
    t.integer "help_content_id"
    t.integer "number"
  end

  create_table "infos", force: true do |t|
    t.string   "title"
    t.datetime "last_modified"
    t.text     "content"
  end

  create_table "jobs", force: true do |t|
    t.datetime "datetime"
    t.string   "action"
    t.string   "arg1"
    t.string   "arg2"
    t.integer  "queue",    default: 0
  end

  add_index "jobs", ["action"], name: "jobs_action_index", using: :btree
  add_index "jobs", ["arg1"], name: "jobs_arg1_index", using: :btree
  add_index "jobs", ["queue"], name: "index_jobs_on_queue", using: :btree

  create_table "lost_links", force: true do |t|
    t.integer "page_id"
    t.integer "section_id"
    t.integer "side_type"
    t.text    "target"
    t.text    "message"
  end

  create_table "mailmagazine_contents", force: true do |t|
    t.integer  "section_id"
    t.integer  "mailmagazine_id"
    t.string   "title"
    t.text     "content"
    t.datetime "datetime"
    t.integer  "send_mailmagazine_id"
    t.integer  "no"
  end

  create_table "mailmagazines", force: true do |t|
    t.integer "section_id"
    t.string  "mail_address"
    t.text    "header"
    t.text    "footer"
  end

  create_table "news", force: true do |t|
    t.integer  "page_id"
    t.datetime "published_at", null: false
    t.string   "title",        null: false
  end

  create_table "page_contents", force: true do |t|
    t.integer  "page_id"
    t.text     "content"
    t.datetime "begin_date"
    t.datetime "end_date"
    t.datetime "last_modified"
    t.text     "mobile"
    t.string   "news_title"
    t.string   "user_name"
    t.string   "tel"
    t.string   "email"
    t.text     "comment"
    t.integer  "admission",        default: 0
    t.integer  "top_news",         default: 0
    t.integer  "section_news",     default: 0
    t.date     "begin_event_date"
    t.date     "end_event_date"
    t.boolean  "latest",           default: false
    t.integer  "format_version",   default: 0
    t.boolean  "edit_required",    default: false
  end

  add_index "page_contents", ["latest"], name: "page_contents_latest_index", using: :btree
  add_index "page_contents", ["page_id"], name: "page_contents_page_id_index", using: :btree

  create_table "page_links", force: true do |t|
    t.integer "page_content_id"
    t.text    "link"
  end

  add_index "page_links", ["link"], name: "page_links_link_index", using: :btree

  create_table "page_locks", force: true do |t|
    t.integer  "page_id"
    t.integer  "status"
    t.integer  "user_id"
    t.datetime "time"
    t.string   "session_id"
  end

  create_table "page_revisions", force: true do |t|
    t.integer  "page_id"
    t.integer  "user_id"
    t.datetime "last_modified"
    t.string   "user_name"
    t.string   "tel"
    t.string   "email"
    t.text     "comment"
  end

  create_table "page_templates", force: true do |t|
    t.string   "name",       null: false
    t.text     "content",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pages", force: true do |t|
    t.integer "genre_id"
    t.string  "name"
    t.string  "title"
    t.integer "original_id"
    t.date    "blog_date"
    t.date    "begin_event_date"
    t.date    "end_event_date"
  end

  add_index "pages", ["genre_id"], name: "pages_genre_id_index", using: :btree

  create_table "schema_info", id: false, force: true do |t|
    t.integer "version"
  end

  create_table "section_news", force: true do |t|
    t.integer  "page_id"
    t.datetime "begin_date"
    t.string   "path"
    t.string   "title"
    t.integer  "genre_id"
  end

  create_table "sections", force: true do |t|
    t.string  "code"
    t.string  "name"
    t.integer "place_code"
    t.text    "info"
    t.integer "top_genre_id"
    t.integer "number"
    t.string  "link"
    t.integer "division_id"
    t.string  "ftp"
    t.integer "feature",                  default: 1
    t.boolean "skip_accessibility_check", default: false
  end

  create_table "sent_mailmagazines", force: true do |t|
    t.datetime "datetime"
    t.integer  "mailmagazine_id"
    t.string   "title"
    t.text     "content"
  end

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree

  create_table "site_components", force: true do |t|
    t.string "name"
    t.text   "value"
  end

  create_table "users", force: true do |t|
    t.string  "name"
    t.integer "section_id"
    t.string  "login"
    t.string  "password"
    t.integer "authority"
    t.string  "mail"
  end

  create_table "web_monitors", force: true do |t|
    t.string  "name"
    t.string  "login"
    t.string  "password"
    t.integer "genre_id"
    t.integer "state",    default: 0
  end

  create_table "words", force: true do |t|
    t.string   "base"
    t.string   "text"
    t.datetime "updated_at", null: false
    t.integer  "user_id"
  end

  add_index "words", ["text"], name: "words_text_index", using: :btree

end
