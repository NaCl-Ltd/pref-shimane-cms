class CreateBasicTables < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists?('action_masters')
      create_table "action_masters" do |t|
        t.string "name"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('board_comments')
      create_table "board_comments" do |t|
        t.integer  "board_id",    null: false
        t.text     "body",        null: false
        t.string   "from",        null: false
        t.boolean  "public"
        t.datetime "created_at",  null: false
        t.datetime "updated_at",  null: false
        t.string   "remote_addr"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('boards')
      create_table "boards" do |t|
        t.string  "title",      null: false
        t.integer "section_id", null: false
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('cms_actions')
      create_table "cms_actions" do |t|
        t.integer "action_master_id"
        t.string  "controller_name"
        t.string  "action_name"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('divisions')
      create_table "divisions" do |t|
        t.string  "name"
        t.integer "number"
        t.boolean "enable"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('emergency_infos')
      create_table "emergency_infos" do |t|
        t.datetime "display_start_datetime", null: false
        t.datetime "display_end_datetime",   null: false
        t.text     "content",                null: false
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('event_referers')
      create_table "event_referers" do |t|
        t.integer "plugin"
        t.string  "path"
        t.string  "target_path"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('genres')
      create_table "genres" do |t|
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
      end
      add_index "genres", ["parent_id"], name: "genres_parent_id_index", using: :btree
      add_index "genres", ["path"], name: "genres_path_index", using: :btree
      add_index "genres", ["section_id"], name: "genres_section_id_index", using: :btree
    end

    unless ActiveRecord::Base.connection.table_exists?('help_actions')
      create_table "help_actions" do |t|
        t.string  "name"
        t.integer "action_master_id"
        t.integer "help_category_id"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('help_categories')
      create_table "help_categories" do |t|
        t.string  "name"
        t.integer "parent_id"
        t.integer "number"
        t.boolean "navigation"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('help_contents')
      create_table "help_contents" do |t|
        t.text "content"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('helps')
      create_table "helps" do |t|
        t.string  "name"
        t.integer "public"
        t.integer "help_category_id"
        t.integer "help_content_id"
        t.integer "number"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('infos')
      create_table "infos" do |t|
        t.string   "title"
        t.datetime "last_modified"
        t.text     "content"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('jobs')
      create_table "jobs" do |t|
        t.datetime "datetime"
        t.string   "action"
        t.string   "arg1"
        t.string   "arg2"
      end
      add_index "jobs", ["action"], name: "jobs_action_index", using: :btree
      add_index "jobs", ["arg1"], name: "jobs_arg1_index", using: :btree
    end

    unless ActiveRecord::Base.connection.table_exists?('lost_links')
      create_table "lost_links" do |t|
        t.integer "page_id"
        t.integer "section_id"
        t.integer "side_type"
        t.text    "target"
        t.text    "message"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('mailmagazine_contents')
      create_table "mailmagazine_contents" do |t|
        t.integer  "section_id"
        t.integer  "mailmagazine_id"
        t.string   "title"
        t.text     "content"
        t.datetime "datetime"
        t.integer  "send_mailmagazine_id"
        t.integer  "no"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('mailmagazines')
      create_table "mailmagazines" do |t|
        t.integer "section_id"
        t.string  "mail_address"
        t.text    "header"
        t.text    "footer"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('news')
      create_table "news" do |t|
        t.integer  "page_id"
        t.datetime "published_at", null: false
        t.string   "title",        null: false
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('page_contents')
      create_table "page_contents" do |t|
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
      end
      add_index "page_contents", ["page_id"], name: "page_contents_page_id_index", using: :btree
    end

    unless ActiveRecord::Base.connection.table_exists?('page_links')
      create_table "page_links" do |t|
        t.integer "page_content_id"
        t.text    "link"
      end
      add_index "page_links", ["link"], name: "page_links_link_index", using: :btree
    end

    unless ActiveRecord::Base.connection.table_exists?('page_locks')
      create_table "page_locks" do |t|
        t.integer  "page_id"
        t.integer  "status"
        t.integer  "user_id"
        t.datetime "time"
        t.string   "session_id"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('page_revisions')
      create_table "page_revisions" do |t|
        t.integer  "page_id"
        t.integer  "user_id"
        t.datetime "last_modified"
        t.string   "user_name"
        t.string   "tel"
        t.string   "email"
        t.text     "comment"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('pages')
      create_table "pages" do |t|
        t.integer "genre_id"
        t.string  "name"
        t.string  "title"
      end
      add_index "pages", ["genre_id"], name: "pages_genre_id_index", using: :btree
    end

    unless ActiveRecord::Base.connection.table_exists?('schema_info')
      create_table "schema_info", id: false do |t|
        t.integer "version"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('section_news')
      create_table "section_news" do |t|
        t.integer  "page_id"
        t.datetime "begin_date"
        t.string   "path"
        t.string   "title"
        t.integer  "genre_id"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('sections')
      create_table "sections" do |t|
        t.string  "code"
        t.string  "name"
        t.integer "place_code"
        t.text    "info"
        t.integer "top_genre_id"
        t.integer "number"
        t.string  "link"
        t.integer "division_id"
        t.string  "ftp"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('sent_mailmagazines')
      create_table "sent_mailmagazines" do |t|
        t.datetime "datetime"
        t.integer  "mailmagazine_id"
        t.string   "title"
        t.text     "content"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('site_components')
      create_table "site_components" do |t|
        t.string "name"
        t.text   "value"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('users')
      create_table "users" do |t|
        t.string  "name"
        t.integer "section_id"
        t.string  "login"
        t.string  "password"
        t.integer "authority"
        t.string  "mail"
      end
    end

    unless ActiveRecord::Base.connection.table_exists?('web_monitors')
      create_table "web_monitors" do |t|
        t.string  "name"
        t.string  "login"
        t.string  "password"
        t.integer "genre_id"
        t.integer "state",    default: 0
      end
    end
  end
end
