class AddTopagesbannerColumn < ActiveRecord::Migration
  def change
    add_column :advertisement_lists, :toppage_ad_number,    :integer
    add_column :advertisements, :toppage_ad_number,    :integer
  end
end
