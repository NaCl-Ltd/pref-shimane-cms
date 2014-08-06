class AddWordsTable < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists?('words')
      create_table "words" do |t|
        t.string   "base", "text"
        t.datetime "updated_at", null: false
        t.integer  "user_id"
      end
      add_index "words", ["text"], name: "words_text_index", using: :btree
    end
  end
end
