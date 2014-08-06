class CreateConsultManagementConsultCategoryMembers < ActiveRecord::Migration
  def change
    create_table :consult_management_consult_category_members do |t|
      t.integer :consult_id
      t.integer :consult_category_id

      t.timestamps
    end
  end
end
