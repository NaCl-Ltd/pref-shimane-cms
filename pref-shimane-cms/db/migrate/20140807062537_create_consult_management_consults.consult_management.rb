# This migration comes from consult_management (originally 20131120061406)
class CreateConsultManagementConsults < ActiveRecord::Migration
  def change
    create_table :consult_management_consults do |t|
      t.string :name
      t.string :link
      t.text :work_content
      t.string :contact
      t.string :text

      t.timestamps
    end
  end
end
