class AddColumnFormatToPageContents < ActiveRecord::Migration
  # マイグレーション限定のPageContentモデルクラス
  class PageContent < ActiveRecord::Base
  end

  def change
    add_column :page_contents, :format_version, :integer, default: 0

    PageContent.reset_column_information
    PageContent.update_all(format_version: 0)
  end
end
