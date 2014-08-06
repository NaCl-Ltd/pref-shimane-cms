class AddColumnSkipAccessibilityCheckToSections < ActiveRecord::Migration
  def change
    add_column :sections, :skip_accessibility_check, :boolean, default: false
  end
end
