# This migration comes from blog_management (originally 20131107050350)
class AddColumnBlogEnabledToGenres < ActiveRecord::Migration
  def change
    add_column :genres, :blog_enabled, :boolean, default: false
  end
end
