class AddFeatureToSection < ActiveRecord::Migration
  def change
    add_column :sections, :feature, :integer, default: 1
  end
end
