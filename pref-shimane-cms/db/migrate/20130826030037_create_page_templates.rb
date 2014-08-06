class CreatePageTemplates < ActiveRecord::Migration
  def change
    create_table :page_templates do |t|
      t.string :name, null: false
      t.text :content, null: false

      t.timestamps
    end
  end
end
