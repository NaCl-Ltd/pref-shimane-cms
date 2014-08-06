# コンテンツの一時保存機能実装のため、edit_required カラム関連の実装をコア側に移行。
# 本 migration ファイルは、移行前の互換性のため。
class AddColumnEditRequiredToPageContents < ActiveRecord::Migration
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
