# This migration comes from blog_management (originally 20131108065252)
class RemoveBlogEnabledAddBlogFolderTypeInGenres < ActiveRecord::Migration
  def up
    remove_column :genres, :blog_enabled, :boolean
    add_column :genres, :blog_folder_type, :integer, :default => ::Genre.blog_folder_types[:none]
  end

  def down
    add_column :genres, :blog_enabled, :boolean, default: false
    remove_column :genres, :blog_folder_type
  end
end
