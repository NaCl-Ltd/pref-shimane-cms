class AddColumnBlogEnabledToGenres < ActiveRecord::Migration
  def change
    add_column :genres, :blog_enabled, :boolean, default: false
  end
end
