class AddColumnEditRequiredToPageContentsUnlessExists < ActiveRecord::Migration
  def up
    unless column_exists?(:page_contents, :edit_required)
      add_column :page_contents, :edit_required, :boolean, default: false
    end
  end

  def down
    if column_exists?(:page_contents, :edit_required)
      remove_column :page_contents, :edit_required
    end
  end
end
