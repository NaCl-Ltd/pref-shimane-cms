class ChangeColumnDefaultNavigationToHelpCategories < ActiveRecord::Migration
  def change
    change_column_default(:help_categories, :navigation, false)
  end
end
