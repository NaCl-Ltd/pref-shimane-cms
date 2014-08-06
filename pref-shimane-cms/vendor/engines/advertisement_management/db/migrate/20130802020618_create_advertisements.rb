class CreateAdvertisements < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists?('advertisements')
      create_table "advertisements" do |t|
        t.string   "name"
        t.string   "advertiser"
        t.string   "image"
        t.string   "alt"
        t.text     "url"
        t.datetime "begin_date"
        t.datetime "end_date"
        t.integer  "side_type"
        t.boolean  "show_in_header"
        t.integer  "corp_ad_number"
        t.integer  "pref_ad_number"
        t.integer  "state",            default: 1
        t.string   "description"
        t.text     "description_link"
      end
    end
  end
end
