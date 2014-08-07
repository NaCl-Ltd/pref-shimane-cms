# This migration comes from blog_management (originally 20131112045656)
class AddColumnBlogDateToPages < ActiveRecord::Migration
  def change
    add_column :pages, :blog_date, :date
  end
end
