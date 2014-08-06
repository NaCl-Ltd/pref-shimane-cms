class CreateAdvertisementLists < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists?('advertisement_lists')
      create_table "advertisement_lists" do |t|
        t.integer "advertisement_id"
        t.integer "state"
        t.integer "pref_ad_number"
        t.integer "corp_ad_number"
      end
    end
  end
end
