class AddColumnBlogDateToPages < ActiveRecord::Migration
  def change
    add_column :pages, :blog_date, :date
  end
end
