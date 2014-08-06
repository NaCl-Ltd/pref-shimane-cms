class AddColumnLatestToPageContents < ActiveRecord::Migration
  def change
    add_column :page_contents, :latest, :boolean, default: false
    add_index :page_contents, :latest, name: "page_contents_latest_index"
  end
end



