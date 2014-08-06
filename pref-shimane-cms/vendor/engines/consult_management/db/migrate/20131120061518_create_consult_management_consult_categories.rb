class CreateConsultManagementConsultCategories < ActiveRecord::Migration
  def change
    create_table :consult_management_consult_categories do |t|
      t.string :name
      t.string :description

      t.timestamps
    end
  end
end
