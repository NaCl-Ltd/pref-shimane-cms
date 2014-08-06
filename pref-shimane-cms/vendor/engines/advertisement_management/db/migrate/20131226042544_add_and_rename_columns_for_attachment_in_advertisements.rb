class AddAndRenameColumnsForAttachmentInAdvertisements < ActiveRecord::Migration
  def change
    # 旧CMSから新CMS移行用のマイグレーションファイルになります。
    # 既に image_file_name カラムが存在している場合は、
    # 下記をコメントアウトを行ってからマイグレートして下さい。
    rename_column :advertisements, :image, :image_file_name
    add_column :advertisements, :image_content_type, :string
    add_column :advertisements, :image_file_size,    :integer
    add_column :advertisements, :image_updated_at,   :datetime
  end
end
